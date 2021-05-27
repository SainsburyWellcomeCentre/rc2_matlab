classdef LickDetect < handle
    
    properties (SetAccess = private)
        
        enabled = false
        
        ctl
        
        n_windows
        window_size_ms
        n_lick_windows
        
        trigger_channel
        trigger_channel_threshold = 2.5  % expect TTL by default
        lick_channel
    end
    
    properties
        
        lick_threshold
    end
    
    properties (SetAccess = private, Hidden = true)
        
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
            
            if ~obj.enabled, return
            end
            
            % if using lick detect, setup parameters
            obj.ctl = ctl;
            
            % essential configuration fields
            obj.n_windows = config.lick_detect.n_windows;
            obj.window_size_ms = config.lick_detect.window_size_ms;
            obj.n_lick_windows = config.lick_detect.n_lick_windows;
            obj.trigger_channel = config.lick_detect.trigger_channel;
            obj.lick_channel = config.lick_detect.lick_channel;
            
            % optional fields
            if isfield(config.lick_detect, 'trigger_channel_threshold')
                obj.trigger_channel_threshold = config.lick_detect.trigger_channel_threshold;
            end
            if isfield(config.lick_detect, 'lick_threshold')
                obj.lick_threshold = config.lick_detect.lick_threshold;
            end
            
            obj.total_window_samples = obj.n_samples_per_window * obj.n_windows;
            
            obj.reset();
        end
        
        
        
        function val = get.n_samples_per_window(obj)
            
            val = floor((obj.window_size_ms/1e3) * obj.ctl.ni_ai_rate);
        end
        
        
        
        function reset(obj)
            
            if ~obj.enabled, return, end
            
            % preallocate array to store lick data
            obj.window_data = nan(obj.n_samples_per_window, obj.n_windows);
            obj.current_window_sample_idx = 1;
            obj.running = false;
        end
        
        
        
        function start_lick_detection(obj)
            
            if ~obj.enabled, return, end
            obj.running = true;
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
            
            end_sample_idx = obj.current_window_sample_idx + length(lick_data) - 1;
            
            if end_sample_idx > obj.total_window_samples
                n_lick_samples = obj.total_window_samples - obj.current_window_sample_idx + 1;
                obj.window_data(obj.current_window_sample_idx:end) = lick_data(1:n_lick_samples);
            else
                obj.window_data(obj.current_window_sample_idx:end_sample_idx) = lick_data;
            end
            
            diff_mtx = diff([[nan, obj.window_data(end, 1:end-1)]; obj.window_data] > obj.lick_threshold, [], 1);
            lick_detected = sum(max(diff_mtx > 0, [], 1)) >= obj.n_lick_windows;
            
            obj.current_window_sample_idx = obj.current_window_sample_idx + length(lick_data);
%             obj.last_lick_sample_value = lick_data(end);
        end
        
        
        
        function lick_detected = loop(obj)
            
            if ~obj.enabled, return
            end
            
            lick_detected = false;
            
            % look for rise in trigger channel
            if ~obj.running  % detection is not running
                
                [trigger_detected, idx] = obj.detect_trigger();
                
                if trigger_detected
                    obj.start_lick_detection();
                    lick_data = obj.ctl.data(idx:end, obj.lick_channel);
                    lick_detected = obj.detect_lick(lick_data);
                end
                
            else  % detection is running
                lick_data = obj.ctl.data(:, obj.lick_channel);
                lick_detected = obj.detect_lick(lick_data);
            end
            
            if lick_detected
                fprintf('lick detected!!\n');
                obj.ctl.give_reward();
                obj.reset();
            end
            
            if obj.current_window_sample_idx > obj.total_window_samples
                obj.reset();
            end
        end
    end
end
