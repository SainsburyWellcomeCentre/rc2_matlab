classdef Reward < handle
% Reward Class for controlling the behaviour of rewards
%
%   Reward Properties:
%       randomize       - whether to randomize the time of reward
%       min_time        - if using randomization the minimum time after
%                         activation the reward should be given
%       max_time        - if using randomization the maximum time after
%                         activation the reward should be given
%       duration        - the duration of the reward in milliseconds
%
%   Private:
%       min_duration    - minimum allowable duration in milliseconds (default = 1ms)
%       max_duration    - maximum allowable duration in milliseconds (default = 500ms)
%       rand_timer      - timer object controlling random rewards
%       pump            - object of Pump class sending the pump signal
%       
%   Reward Methods:
%       start_reward       - activate the reward (either give or start timer)
%       set_duration       - set the duration of the reward
%       give_reward        - immediately give a reward
    
    properties
        
        randomize
        min_time
        max_time
    end
    
    properties (SetObservable = true, SetAccess = private)
    
        duration
    end
    
    properties (SetAccess = private)
        
        min_duration = 1;
        max_duration = 500;
        rand_timer
    end
    
    properties (Hidden = true)
        
        pump
    end
    
    
    methods
        
        function obj = Reward(pump, config)
        %%obj = REWARD(pump, config)
        %   Main class for controlling presentation of reward.
        %       Acts on the pump class.
        
            obj.pump = pump;
            
            % control the randomization of the reward
            obj.randomize = config.reward.randomize;
            obj.min_time = config.reward.min_time;
            obj.max_time = config.reward.max_time;
            
            % duration
            obj.duration = config.reward.duration;
        end
        
        
        function start_reward(obj, wait_for_reward)
        %%START_REWARD(obj, wait_for_reward)
        %   Starts the timing of the reward, or just presents the reward.
        %       This class should be used for all presentation of rewards.
        %       If an immediate reward is required set wait_for_reward to
        %       zero.
        
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
                    delete(obj.rand_timer)
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
                start(obj.rand_timer)
            end
        end
        
        
        function status = set_duration(obj, val)
        %%status = SET_DURATION(obj, val)
        %   Sets the duration of the reward (i.e. pump on)
        %   Inputs:
        %       val - value to use for the duration in milliseconds.
        %   Outputs:
        %       status - 0 on success, 1 on failure
        
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
        %%GIVE_REWARD(obj, ~, ~)
        %   Set the pump to pulse for obj.duration milliseconds.
        
            obj.pump.pulse(obj.duration);
        end
    end
end