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
        running = false
        abort = false
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
                
                %cfg = obj.get_config();
                %obj.ctl.save_single_trial_config(cfg);
                
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % make sure the treadmill is blocked
                obj.ctl.block_treadmill();
                
                % load teensy and listen to correct source
                obj.ctl.teensy.load(obj.direction);
                obj.ctl.multiplexer.listen_to(obj.vel_source);
                
                % start listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('soloist');
                
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.prepare_acq();
                    obj.ctl.start_acq();
                end
                
                % start the move to operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                % start integrator
                obj.ctl.reset_pc_position();
                
                % the soloist will connect, setup some parameters and then
                % wait for the solenoid signal to go low
                % we need to give it some time to setup (~2s, but we want
                % to wait at the start position anyway...
                proc = obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit, 'teensy');
                
                % wait five seconds
                % TODO: 
                pause(5)
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging the single trial
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                % wait for process to terminate.
                % TODO:  setup an event to unblock treadmill on digital
                % input.
                while ~obj.ctl.trigger_input.read()  
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % stop logging the single trial.
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
                    obj.ctl.stop_sound();
                end
                
                obj.running = false;
                
            catch ME
                
                % if an error has occurred, perform the following whether
                % or not the single protocol is handling the acquisition
                obj.running = false;
                obj.ctl.soloist.abort();
                obj.ctl.block_treadmill();
                obj.ctl.stop_acq();
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                obj.ctl.stop_sound();
                rethrow(ME)
            end
        end
        
        
        function stop(obj)
            
            obj.abort = true;
        end
        
        
        function prepare_as_sequence(~, ~, ~)
        end
        
        
        function cfg = get_config(obj)
        end
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.abort = false;
            
            obj.ctl.block_treadmill()
            
            if obj.handle_acquisition
                obj.ctl.soloist.abort();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
            end
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
            
        end
    end
end