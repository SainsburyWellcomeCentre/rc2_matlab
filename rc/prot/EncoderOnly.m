classdef EncoderOnly < handle
    
    properties
        
        stage_pos
        back_limit
        forward_limit
        direction
        handle_acquisition = true
        wait_for_reward = true
        
        log_trial = false
        
        integrate_using = 'teensy'  % 'teensy' or 'pc'
    end
    
    properties (SetAccess = private)
        log_trial_fname
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = EncoderOnly(ctl, config)
            obj.ctl = ctl;
            obj.stage_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_only';
        end
        
        function run(obj)
            
            try
                
                % load correct direction on teensy
                obj.ctl.teensy.load(obj.direction);
                
                
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                    obj.ctl.start_acq();
                end
                
                % move to position along stage where the trial will take
                % place
                proc = obj.ctl.soloist.move_to(obj.stage_pos, true);
                proc.wait_for(0.5);
                
                % wait a bit of time before starting the trial
                pause(5)
                
                % start integrator
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.reset_teensy_position();
                else
                    obj.ctl.reset_position();
                end
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging velocity if required.
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                % wait for trigger from teensy
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.wait_for_teensy();
                else
                    obj.ctl.integrate_until();
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % stop logging single trial
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