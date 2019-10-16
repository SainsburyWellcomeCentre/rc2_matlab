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
        
        function obj = Coupled(ctl, config)
            
            obj.ctl = ctl;
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_only';
            obj.vel_source = 'teensy';
        end
        
        
        
        function run(obj)
            
            try
                
                obj.ctl.teensy.load(obj.direction);
                obj.ctl.multiplexer.listen_to(obj.vel_source);
                
                % start integrator
                obj.ctl.reset_position();
                
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
                % make sure the stage has moved foward
                if obj.ctl.get_position() > 0
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
                end
                
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                end
                
            catch ME
                obj.ctl.treadmill_block();
                obj.ctl.stop_acq();
                obj.ctl.stop_logging_single_trial();
                rethrow(ME)
            end
        end
        
        
        function prepare_as_sequence(~, ~, ~)
        end
    end
end