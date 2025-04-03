classdef Reward_DoubleRotation < handle
    % Reward class for controlling the behaviour of rewards.
    
    properties
        randomize % Boolean indicating whether to randomize the time of reward.
        min_time % If :attr:`randomize` is true, specifies the minimum time after activation that the reward should be given.
        max_time % If :attr:`randomize` is true, specifies the maximum time after activation that the reward should be given.
    end
    
    properties (SetObservable = true, SetAccess = private)
        n_rewards_counter = 0; % Counter for the number of rewards delivered. 
        
    end

    properties (SetObservable = true)
        duration % The duration of the reward in milliseconds.
    end

    properties (SetAccess = private)
        min_duration = 1; % Minimum allowable duration in milliseconds (default = 1ms).
        max_duration = 5000; % Maximum allowable duration in milliseconds (default = 500ms).
        rand_timer % `timer <https://uk.mathworks.com/help/matlab/ref/timer.html>`_ object controlling random rewards.
        total_duration_on = 0; % Total duration of all reward pulses in milliseconds.
    end
    
    properties (SetAccess = private, Hidden = true)
        pump % Handle to :class:`rc.classes.Pump` object sending the pump signal.
    end
    
    
    
    methods
        
        function obj = Reward_DoubleRotation(pump, config)
            % Constructor for a :class:`rc.classes.Reward` action.
            %
            % :param pump: :class:`rc.classes.Pump` object.
            % :param config: The main configuration file.
        
            obj.pump = pump;
            
            % control the randomization of the reward
            obj.randomize = config.reward.randomize;
            obj.min_time = config.reward.min_time;
            obj.max_time = config.reward.max_time;
            
            % duration
            obj.duration = config.reward.duration;
        end
        
        
        
        function reset_n_rewards_counter(obj)
        %%Resets the counters
            obj.n_rewards_counter = 0;
            obj.total_duration_on = 0;
        end
        
        
        
        function start_reward(obj, wait_for_reward)
            % Starts the timing of the reward, or just present the reward. This class should be used for all presentation of rewards.
            %
            % :param wait_for_reward: Delay in milliseconds before reward given. For immediate reward set to 0.
        
            % interval to wait before presentation of reward
            if ~obj.randomize
                
                % set the interval to minimum interval.
                interval = 0.01;
            else
                
                % interval is a random time between the min and max
                interval = obj.min_time + (obj.max_time-obj.min_time)*rand;
                interval = round(interval*100)/100;
            end
            
            
            % delete old timers
            if ~isempty(obj.rand_timer)
                if isvalid(obj.rand_timer)
                    return
%                     delete(obj.rand_timer)
                end
            end
            
            
            % whether to wait for reward to complete before returning
            if wait_for_reward
                
                % this will block... could reimplement as tic/toc loop
                pause(interval)
                obj.give_reward()
                pause(obj.duration*1e-3 + 0.5) % 
            else
                
                % start a timer to give reward after a certain interval
                obj.rand_timer = timer();
                obj.rand_timer.StartDelay = interval;
                obj.rand_timer.TimerFcn = @(src, evt)obj.give_reward(src, evt);
                obj.rand_timer.StopFcn = @(src, evt)obj.delete_timer(src, evt);
                start(obj.rand_timer)
            end
        end
        
        
        
        function status = set_duration(obj, val)
            % Sets the :attr:`duration` property.
            %
            % :param val: Value to use for the duration in milliseconds.
            % :return: Status code: 0 for success, 1 for failure.
        
            % return status
            status = 0;
            if val <= obj.min_duration || val > obj.max_duration
                status = -1;
                return
            end
            
            % set the duration
            obj.duration = val;
        end
    end
    
    
    
    methods (Access = private)
        function give_reward(obj, ~, ~)
            % Set the pump to pulse for :attr:`duration`.
        
            obj.pump.pulse(obj.duration);
            
            obj.n_rewards_counter = obj.n_rewards_counter + 1;
            obj.total_duration_on = obj.total_duration_on + obj.duration;
        end
        
        
        
        function delete_timer(obj, ~, ~)
            
            delete(obj.rand_timer)
        end
    end
end
