classdef Reward < handle
    
    properties
        ni
        chan
        randomize
        min_time
        max_time
        duration
        rand_timer
    end
    
    
    methods
        
        function obj = Reward(ni, config)
            obj.ni = ni;
            
            all_channel_names = obj.ni.do_names();
            this_name = config.reward.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            obj.randomize = config.reward.randomize;
            obj.min_time = config.reward.min_time;
            obj.max_time = config.reward.max_time;
            obj.duration = config.reward.duration;
        end
        
        
        function start_reward(obj)
            
            if ~obj.randomize
                interval = 0.01;
            else
                interval = obj.min_time + (obj.max_time-obj.min_time)*rand;
                interval = round(interval*100)/100;
            end
            
            % delete old timers
            if ~isempty(obj.rand_timer)
                if isvalid(obj.rand_timer)
                    delete(obj.rand_timer)
                end
            end
            
            obj.rand_timer = timer();
            obj.rand_timer.StartDelay = interval;
            obj.rand_timer.TimerFcn = @(src, evt)obj.give_reward(src, evt);
            start(obj.rand_timer)
        end
        
        
        function give_reward(obj, ~, ~)
            obj.ni.do_pulse(obj.chan, obj.duration);
        end
    end
end