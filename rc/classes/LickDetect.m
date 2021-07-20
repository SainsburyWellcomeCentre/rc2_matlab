classdef LickDetect < handle
    
    properties (SetAccess = private)
        
        enabled = false
        
        ctl
        trigger_channel
        trigger_channel_threshold = 2.5  % expect TTL by default
        lick_channel
        
        lick_times = nan(100000, 1);
    end
    
    properties
        
        n_windows
        window_size_ms
        n_lick_windows
        n_consecutive_windows
        detection_window_is_triggered
        lick_threshold
        enable_reward = true
    end
    
    properties (SetObservable = true)
        n_licks_detected = 0
        last_lick_time = nan
        lick_occurred_in_window = -1
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
    end
    
    
    
    methods
        
        function obj = LickDetect(ctl, config)
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
            obj.detection_window_is_triggered = config.lick_detect.detection_window_is_triggered;
            
            % optional fields
            if isfield(config.lick_detect, 'trigger_channel_threshold')
                obj.trigger_channel_threshold = config.lick_detect.trigger_channel_threshold;
            end
            if isfield(config.lick_detect, 'lick_threshold')
                obj.lick_threshold = config.lick_detect.lick_threshold;
            end
            
            obj.total_window_samples = obj.n_samples_per_window * obj.n_windows;
            
            obj.reset_counters();
            obj.reset_window();
        end
        
        
        
        function val = get.n_samples_per_window(obj)
            
            val = floor((obj.window_size_ms/1e3) * obj.ctl.ni_ai_rate);
        end
        
        
        
        function reset(obj)
            
            if ~obj.enabled, return, end
            
            obj.reset_counters();
            obj.reset_window();
        end
        
        
        
        function reset_counters(obj)
            
            if ~obj.enabled, return, end
            
            obj.n_licks_detected    = 0;
            obj.lick_times          = nan(100000, 1);
            obj.last_lick_time      = nan;
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
            
            trigger_data = [obj.last_trigger_sample_value;  obj.ctl.data(:, obj.trigger_channel) > obj.trigger_channel_threshold];
            idx = find(diff(trigger_data) == 1, 1);
            trigger_detected = ~isempty(idx);
            
            % store last value in the rare case trigger goes up between
            % logging batches
            obj.last_trigger_sample_value = obj.ctl.data(end, obj.trigger_channel);
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
            diff_mtx = diff([[nan, obj.window_data(end, 1:end-1)]; obj.window_data] > obj.lick_threshold, [], 1);
            
            % has lick occurred in the window
            lick_in_window = max(diff_mtx > 0, [], 1);
            
            % new lick detection criteria... licks must occur in
            % a subset of consecutive windows
            lick_detected = any(sum(lick_in_window(obj.consecutive_window_idx), 1) >= obj.n_lick_windows);
            
            % old criteria - >= obj.n_lick_windows across all windows
%             lick_detected = sum(lick_in_window) >= obj.n_lick_windows;
            
            obj.current_window_sample_idx = obj.current_window_sample_idx + length(lick_data);
%             obj.last_lick_sample_value = lick_data(end);
        end
        
        
        
        function lick_detected = loop(obj)
            
            if ~obj.enabled, return, end
            
            % 'detection_window_is_triggered' == 0
            %       look for licks continuously
            % 'detection_window_is_triggered' == 1
            %       look for a rise in the trigger input, and then look for
            %       licks in a window after that rise
            % 'detection_window_is_triggered' == 2
            %       look for the trigger input to be high, give a reward
            %       upon licks
            if obj.detection_window_is_triggered == 1
                
                lick_detected = false;
                
                % look for rise in trigger channel
                if ~obj.running  % detection is not running
                    
                    [trigger_detected, idx] = obj.detect_trigger();
                    
                    if trigger_detected
                        obj.running = true;
                        lick_data = obj.ctl.data(idx:end, obj.lick_channel);
                        lick_detected = obj.detect_lick(lick_data);
                    end
                    
                else  % detection is running
                    
                    lick_data = obj.ctl.data(:, obj.lick_channel);
                    lick_detected = obj.detect_lick(lick_data);
                end
                
                if lick_detected
                    obj.on_lick_detected()
                end
                
                if obj.current_window_sample_idx > obj.total_window_samples
                    % if beyond the lick window reset
                    obj.lick_occurred_in_window = 0;
                    obj.reset_window();
                end
                
            elseif obj.detection_window_is_triggered == 2
                
                % trigger channel data
                trigger_data = obj.ctl.data(:, obj.trigger_channel);
                % append last trigger value
                trigger_data = [obj.last_trigger_sample_value; trigger_data];
                % take lick data where trigger high
                trigger_high = trigger_data > obj.trigger_channel_threshold;
                
                % no trigger detected.. do nothing
                if sum(trigger_high) == 0
                    obj.last_trigger_sample_value = obj.ctl.data(end, obj.trigger_channel);
                    obj.last_lick_sample_value = obj.ctl.data(end, obj.lick_channel);
                    return
                end
                
                % trigger went high in this window
                if any(diff(trigger_high) == 1)
                    obj.running = true;
                end
                
                lick_data = obj.ctl.data(trigger_high(2:end), obj.lick_channel);
                
                % append the last value from the previous batch or previous
                % sample
                if trigger_high(2)
                    lick_data = [obj.last_lick_sample_value; lick_data];
                end
                
                % look for rises in the lick data in this time
                lick_detected = any(diff(lick_data > obj.lick_threshold, [], 1) == 1);
                
                % if lick detected, give reward and store information
                if lick_detected
                    obj.on_lick_detected();
                end
                
                % if trigger was previously detected but window ends low,
                % then no detection longer running
                % print out lick_occurred_in_window false... in case no
                % lick was detected
                if obj.running && trigger_high(end) == 0
                    obj.lick_occurred_in_window = 0;
                    obj.running = false;
                end
                
                % store the trigger and lick channel value at last window
                obj.last_trigger_sample_value = obj.ctl.data(end, obj.trigger_channel);
                obj.last_lick_sample_value = obj.ctl.data(end, obj.lick_channel);
                
            else
                
                % if lick detection window not externally triggered, just
                % keep looking for licks
                lick_data = obj.ctl.data(:, obj.lick_channel);
                lick_detected = obj.detect_lick(lick_data);
                
                if lick_detected
                    obj.on_lick_detected()
                end
                
                if obj.current_window_sample_idx > obj.total_window_samples
                    % if beyond the lick window reset
                    obj.lick_occurred_in_window = 0;
                    obj.reset_window();
                end
            end
        end
        
        
        
        function on_lick_detected(obj)
            
            % store the time of the lick
            obj.n_licks_detected = obj.n_licks_detected + 1;
            obj.last_lick_time = toc(obj.ctl.tic);
            obj.lick_times(obj.n_licks_detected) = obj.last_lick_time;
            
            % give the reward and reset the window
            if obj.enable_reward
                obj.ctl.give_reward();
            end
            
            obj.lick_occurred_in_window = 1;
            
            obj.reset_window();
        end
    end
end
