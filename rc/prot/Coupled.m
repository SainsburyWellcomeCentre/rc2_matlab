classdef Coupled < handle
    
    properties
        
        start_pos
        back_limit
        forward_limit
        direction
        vel_source
        handle_acquisition = true
        wait_for_reward = true
        
        log_trial = false
    end
    
    properties (SetAccess = private)
        log_trial_fname
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = Coupled(ctl)
            obj.ctl = ctl;
            obj.start_pos = ctl.config.stage.start_pos;
            obj.back_limit = ctl.config.stage.back_limit;
            obj.forward_limit = ctl.config.stage.forward_limit;
            obj.direction = 'forward_only';
            obj.vel_source = 'teensy';
        end
        
        
        function run(obj)
            
            obj.ctl.teensy.load(obj.direction);
            obj.ctl.multiplexer.listen_to(obj.vel_source);
            
            if obj.handle_acquisition
                obj.ctl.prepare_acq();
                obj.ctl.start_acq();
            end
            
            % start a process which will take 5 seconds
            proc = obj.ctl.soloist.block_test();
            % proc = obj.ctl.soloist.move_to(obj.start_pos, true);
            
            proc.wait_for(0.5);
            
            % wait a bit of time before starting the trial
            pause(5)
            
            % release block on the treadmill
            obj.ctl.treadmill.unblock()
            
            
            if obj.log_trial
                obj.log_trial_fname = obj.ctl.start_logging_single_trial();
            end
            
                
            % start a process which will take 5 seconds
            proc = obj.ctl.soloist.block_test();
            % obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit)
            
            proc.wait_for(0.5);
            
            obj.ctl.treadmill.block()
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
            
            % wait for reward to complete then stop acquisition
            obj.ctl.reward.start_reward(obj.wait_for_reward)
            
            if obj.handle_acquisition
                obj.ctl.stop_acq();
            end
        end
    end
end