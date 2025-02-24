classdef LickDetect_DoubleRotation < handle
    
    properties (SetAccess = private)
        
        enabled = false
        
        ctl
        trigger_channel
        trigger_channel_threshold = 2.5  % expect TTL by default
        lick_channel
        lickpower_channel

        lick_times = nan(100000, 1);
    end
    
    properties
        
        lick_detected
        n_windows
        window_size_ms
        n_lick_windows
        n_consecutive_windows
        detection_trigger_type
        lick_threshold
        enable_reward = true

        delay
    end
    
    properties (SetAccess = private, Hidden = true)
        
        consecutive_window_idx
        n_samples_per_window
        window_data
        total_window_samples
        last_trigger_sample_value = 0
        last_lick_sample_value = 0
        running = false
        current_window_sample_idx

        ni % Handle to the :class:`rc.nidaq.NI` object.
        state % Current state of the digital output (1 or 0).
    end
    
    
    
    methods
        
        function obj = LickDetect_DoubleRotation(ctl, config)
        %% LickDetect(ctl, config)
        %   Module for providing rewards based on lick behaviour.
        %
        %   Currently, listens to a TTL on an analog input.
        %   When the TTL goes high, it starts monitoring another analog
        %   input channel (the lick data).
        %   If the lick data voltage increases beyond a threshold value in
        %   a certain number of time "windows", a reward is given.
        %
        %   Inputs:
        %       ctl:            main RC2 controller object
        %       config:         config structure with field 'lick_detect'
        %                           (a structure)
        %                       if enabled 'lick_detect' 
        %
        %   Properties:
        %       enabled:        whether to use LickDetect module (default:
        %                       false)
        %       n_windows:      number of time windows in which to examine
        %                       lick data
        %       window_size_ms: the size in ms of each of these windows
        %       n_lick_windows: the number of time windows in which licking
        %                       must be detected, before giving a reward
        %       trigger_channel: the analog input channel on which to look
        %                       for a trigger to start the detection
        %       lick_channel:   the analog input channel which contains the
        %                       lick data
        %       lick_threshold: voltage threshold above which a lick is determined
        %       (trigger_channel_threshold):  voltage threshold above which
        %                       a trigger is detected (default: 2.5)
        
            obj.enabled = config.lick_detect.enable;
            
            if ~obj.enabled, return, end
            
            % if using lick detect, setup parameters
            obj.ctl = ctl;
            
            % essential configuration fields
            obj.n_windows = config.lick_detect.n_windows;
            obj.window_size_ms = config.lick_detect.window_size_ms;
            obj.n_lick_windows = config.lick_detect.n_lick_windows;
            obj.n_consecutive_windows = config.lick_detect.n_consecutive_windows;
            obj.trigger_channel = config.lick_detect.trigger_channel;
            obj.lick_channel = config.lick_detect.lick_channel;
            obj.lickpower_channel = config.lick_detect.lickpower_channel;
            obj.detection_trigger_type = config.lick_detect.detection_trigger_type;
            obj.delay = config.lick_detect.delay;
            
            obj.ni = obj.ctl.ni;

           

            % optional fields
            if isfield(config.lick_detect, 'trigger_channel_threshold')
                obj.trigger_channel_threshold = config.lick_detect.trigger_channel_threshold;
            end
            if isfield(config.lick_detect, 'lick_threshold')
                obj.lick_threshold = config.lick_detect.lick_threshold;
            end
            
            obj.total_window_samples = obj.n_samples_per_window * obj.n_windows;
            
            obj.reset_window();
        end
        
        
        
        function val = get.n_samples_per_window(obj)
            
            val = floor((obj.window_size_ms/1e3) * obj.ctl.ni_ai_rate);
        end
        
        
        
        function reset(obj)
            
            if ~obj.enabled, return, end
            
            obj.reset_window();
        end
        
        
        function start_trial(obj)
            
            obj.lick_detected = false;
            obj.reset_window();
        end
        
        
        function reset_window(obj)
            
            if ~obj.enabled, return, end
            
            % preallocate array to store lick data
            obj.window_data = nan(obj.n_samples_per_window, obj.n_windows);
            obj.consecutive_window_idx = bsxfun(@plus, (1:obj.n_consecutive_windows)', (0:(obj.n_windows-obj.n_consecutive_windows)));
            obj.current_window_sample_idx = 1;
            obj.running = false;
        end
        
        
        
        function [trigger_detected, idx] = detect_trigger(obj)
            
            trigger_data = [obj.last_trigger_sample_value;  obj.ctl.tdata(:, obj.trigger_channel) > obj.trigger_channel_threshold]; % obj.ctl.data
            idx = find(diff(trigger_data) == 1, 1);
            trigger_detected = ~isempty(idx);
            
            % store last value in the rare case trigger goes up between
            % logging batches
            obj.last_trigger_sample_value = obj.ctl.tdata(end, obj.trigger_channel); % obj.ctl.data
        end
        
        
        
        function lick_detected = detect_lick(obj, lick_data)
            
            % the last sample point after including this set of lick data
            end_sample_idx = obj.current_window_sample_idx + length(lick_data) - 1;
            
            % if that sample point is beyond all windows
            if end_sample_idx > obj.total_window_samples
                % restrict the lick data to just that occurring within the
                % windows
                n_lick_samples = obj.total_window_samples - obj.current_window_sample_idx + 1;
                obj.window_data(obj.current_window_sample_idx:end) = lick_data(1:n_lick_samples);
            else
                % otherwise take all the lick data
                obj.window_data(obj.current_window_sample_idx:end_sample_idx) = lick_data;
            end
            
            % put the last sample of the previous window in front of the
            % next window in case lick rises above threshold on first
            % sample point of window
            % find sample points above the lick threshold and take the
            % difference along columnes (i.e. in each window)
            diff_mtx = diff([[nan, obj.window_data(end, 1:end-1)]; obj.window_data] > obj.lick_threshold(1) & [[nan, obj.window_data(end, 1:end-1)]; obj.window_data] < obj.lick_threshold(2), [], 1);
            
            % has lick occurred in the window
            lick_in_window = max(diff_mtx > 0, [], 1);
            
            % new lick detection criteria... licks must occur in
            % a subset of consecutive windows
            lick_detected = any(sum(lick_in_window(obj.consecutive_window_idx), 1) >= obj.n_lick_windows);
            
            obj.current_window_sample_idx = obj.current_window_sample_idx + length(lick_data);
        end
        
        
        
        function loop(obj)
            
            if ~obj.enabled, return, end
            
            % 'detection_trigger_type' == 1
            %       look for a rise in the trigger input, and then look for
            %       licks in a window after that rise
            % 'detection_trigger_type' == 2
            %       look for the trigger input to be high, give a reward
            %       upon licks
            if obj.detection_trigger_type == 1
                
                lick_detected_internal = false;
                
                % look for rise in trigger channel
                if ~obj.running  % detection is not running
                    
                    [trigger_detected, idx] = obj.detect_trigger();
                    
                    if trigger_detected
                        obj.running = true;
                        lick_data = obj.ctl.tdata(idx:end, obj.lick_channel);   % obj.ctl.data
                        lick_detected_internal = obj.detect_lick(lick_data);
                    end
                    
                else  % detection is running
                    
                    lick_data = obj.ctl.tdata(:, obj.lick_channel);     % obj.ctl.data
                    lick_detected_internal = obj.detect_lick(lick_data);
                end
                
                if lick_detected_internal
                    obj.lick_detected = true;
                    if obj.enable_reward
                        obj.ctl.give_reward();
%                     else
%                         system('C:\Users\Margrie_Lab1\Documents\MATLAB\tools\nircmd.exe setsysvolume 4000');
                    end
                    obj.reset_window();
                end
                
                if obj.current_window_sample_idx > obj.total_window_samples
                    obj.reset_window();
                end
                
            elseif obj.detection_trigger_type == 2
                
                % trigger channel data
                trigger_data = obj.ctl.tdata(:, obj.trigger_channel);       % obj.ctl.data
                % append last trigger value
                trigger_data = [obj.last_trigger_sample_value; trigger_data];
                % take lick data where trigger high
                trigger_high = trigger_data > obj.trigger_channel_threshold;
                
                % store for next iteration
                obj.last_trigger_sample_value = trigger_data(end);
                
                % no trigger detected.. do nothing
                if sum(trigger_high) == 0
                    obj.last_lick_sample_value = obj.ctl.tdata(end, obj.lick_channel);      % obj.ctl.data
                    return
                end
                
                % get lick data - append last lick value
                lick_data = [obj.last_lick_sample_value; obj.ctl.tdata(:, obj.lick_channel)];   % lick_data = [obj.last_lick_sample_value; obj.ctl.data(:, obj.lick_channel)];
                obj.last_lick_sample_value = lick_data(end);
                
                % find points where lick data crosses threshold
                %    we append a false at the beginning because if the lick
                %    data went high on that last sample, it should have
                %    been picked up in the previous window, and also the
                %    lick data will already be above threshold
                lick_crossed_threshold = [false; diff(lick_data > obj.lick_threshold(1) & lick_data < obj.lick_threshold(2), [], 1) == 1];
                
                % if lick crossed threshold whilst trigger was high, reward
                if any(trigger_high(lick_crossed_threshold))
                    % give the reward
                    if obj.enable_reward
                        obj.ctl.give_reward();
                    end
                    obj.lick_detected = true;
                end
            end
        end

        function power_on(obj)
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.lickpower_channel, true);
            obj.state = true;
        end

        function power_off(obj)
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.lickpower_channel, false);
            obj.state = false;
        end

    end
end
