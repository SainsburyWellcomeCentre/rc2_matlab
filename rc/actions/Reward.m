classdef Reward < handle
    
    properties
        
        pump
        
        randomize
        min_time
        max_time
        
        rand_timer
    end
    
    properties (SetObservable = true, SetAccess = private)
    
        duration
    end
    
    
    
    methods
        
        function obj = Reward(pump, config)
            
            obj.pump = pump;
            
            obj.randomize = config.reward.randomize;
            obj.min_time = config.reward.min_time;
            obj.max_time = config.reward.max_time;
            obj.duration = config.reward.duration;
        end
        
        
        function start_reward(obj, wait_for_reward)
            
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
            
            % whether to wait for reward to complete before returning
            if wait_for_reward
                pause(interval)
                obj.give_reward()
                pause(obj.duration*1e-3+0.5)
            else
                obj.rand_timer = timer();
                obj.rand_timer.StartDelay = interval;
                obj.rand_timer.TimerFcn = @(src, evt)obj.give_reward(src, evt);
                start(obj.rand_timer)
            end
        end
        
        
        function give_reward(obj, ~, ~)
            obj.pump.pulse(obj.duration);
        end
        
        
        function status = set_duration(obj, val)
            status = 0;
            if val < 0 || val > 500
                fprintf('reward duration must be between 0 and 500 ms\n');
                status = -1;
                return
            end
            obj.duration = val;
        end
    end
end