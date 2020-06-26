classdef Coupled < handle
    
    properties
        
        start_dwell_time = 5
        start_pos
        back_limit
        forward_limit
        direction
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        log_trial = false
        log_fname = ''
    end
    
    properties (SetAccess = private)
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
        end
        
        
        function final_position = run(obj)
            
            try
                
                % report the end position
                final_position = 0;
                
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % startup initial communication
                proc = obj.ctl.soloist.communicate();
                proc.wait_for(0.5);
                
                % prepare to acquire data
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                % make sure the treadmill is blocked
                obj.ctl.block_treadmill();
                
                % make sure vis stim is off
                obj.ctl.vis_stim.off();
                
                % load teensy
                obj.ctl.teensy.load(obj.direction);
                
                % get and save config
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to correct source
                obj.ctl.multiplexer_listen_to('teensy');
                
                % start PC listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('soloist');
                
                % if this protocol is handling itself start the sound and
                % prepare the acquisition
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % start the move to operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                % reset position
                obj.ctl.reset_pc_position();
                
                % Retrieve the *EXPECTED* offset on the soloist, given the
                % current conditions and a prior calibration value:
                %   solenoid - up
                %   gear mode - off
                %   listening to - Teensy
                %obj.ctl.soloist.ai_offset = obj.ctl.offsets.get_soloist_offset('teensy', 'up', 'on');
                
                % Get the *CURRENT* error on the soloist when that expected
                % voltage is applied.
                % This line applies the *EXPECTED* offset on the soloist and returns 
                % the residual error
                obj.ctl.soloist.reset_pso();
                real_time_offset_error = ...
                    obj.ctl.soloist.calibrate_zero(obj.back_limit, obj.forward_limit, 0); % obj.ctl.soloist.ai_offset
                
                % Retrieve the *EXPECTED* offset on the soloist, given the
                % conditions to be used in the task:
                %   solenoid - down
                %   gear mode - on
                %   listening to - Teensy
                %obj.ctl.soloist.ai_offset = obj.ctl.offsets.get_soloist_offset('teensy', 'down', 'on');
                
                % Subtract the residual voltage (if the residual error was
                % positive, we need to subtract it)
                obj.ctl.soloist.ai_offset = -real_time_offset_error + 1.2;%obj.ctl.soloist.ai_offset - real_time_offset_error;
                
                % the soloist will connect, setup some parameters and then
                % wait for the solenoid signal to go low
                % we need to give it some time to setup (~2s, but we want
                % to wait at the start position anyway...
                obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit);
                
                % switch vis stim on
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.on();
                else
                    obj.ctl.vis_stim.off();
                end
                
                % start integrating position
                obj.ctl.position.start();
                
                % wait a bit
                tic;
                while toc < obj.start_dwell_time
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging the single trial if required
                if obj.log_trial
                    
                    % open file for logging
                    obj.ctl.start_logging_single_trial(obj.log_fname);
                end
                
                % wait for stage to reach the position
                while ~obj.ctl.trigger_input.read()  
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        %obj.cleanup();
                        return
                    end
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % switch vis stim off
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.off();
                end
                
                % stop integrating position
                obj.ctl.position.stop();
                
                % stop logging the single trial.
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % Wait for reward to complete then stop acquisition
                % make sure the treadmill has moved foward
                if obj.ctl.get_position() > 0
                    final_position = 1;
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
                end
                
                obj.ctl.soloist.reset_pso();
                
                % if handling the acquisition stop 
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
                % the protocol is no longer running
                obj.running = false;
                
            catch ME
                
                % if an error has occurred, perform the following whether
                % or not the single protocol is handling the acquisition
                obj.running = false;
                obj.ctl.soloist.stop();
                obj.ctl.block_treadmill();
                obj.ctl.vis_stim.off();
                obj.ctl.position.stop();
                obj.ctl.stop_acq();
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                obj.ctl.stop_sound();
                
                rethrow(ME)
            end
        end
        
        
        function stop(obj)
            % if the stop method is called, set the abort property
            % temporarily to true
            % the main loop will detect this and abort properly
            obj.abort = true;
        end
        
        
        function cfg = get_config(obj)
            
            cfg = { 
                    'prot.time_started',        datestr(now, 'yyyymmdd_HH_MM_SS')
                    'prot.type',                class(obj);
                    'prot.start_pos',           sprintf('%.3f', obj.start_pos);
                    'prot.stage_pos',           '---';
                    'prot.back_limit',          sprintf('%.3f', obj.back_limit);
                    'prot.forward_limit',       sprintf('%.3f', obj.forward_limit);
                    'prot.direction',           obj.direction;
                    'prot.start_dwell_time',    sprintf('%.3f', obj.start_dwell_time);
                    'prot.handle_acquisition',  sprintf('%i', obj.handle_acquisition);
                    'prot.wait_for_reward',     sprintf('%i', obj.wait_for_reward);
                    'prot.log_trial',           sprintf('%i', obj.log_trial);
                    'prot.log_fname',           sprintf('%s', obj.log_fname);
                    'prot.integrate_using',     '---';
                    'prot.wave_fname',          '---';
                    'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                    'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                    'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                    'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration)};
        end
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.abort = false;
            
            fprintf('running cleanup in coupled\n')
            
            obj.ctl.block_treadmill()
            obj.ctl.vis_stim.off();
            obj.ctl.position.stop();
            
            if obj.handle_acquisition
                obj.ctl.soloist.stop();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
            end
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
        end
    end
end