classdef Coupled < handle
    % Coupled class for handling trials in which the treadmill velocity is
    % coupled to the linear stage velocity.

    properties
        start_dwell_time = 5 % Time in seconds to wait at the beginning of the trial.
        start_pos % Position (in Soloist units) at the start of the trial.
        back_limit % Backward position beyond which the trial is stopped.
        forward_limit % Forward position beyond which the trial is stopped and reward given.
        direction % Direction of travel (name of Teensy script, e.g. 'forward_only' or 'forward_and_backward').
        handle_acquisition = true % Boolean specifying whether we are running this as a single trial (true) or as part of a :class:`rc.prot.ProtocolSequence` (false).
        wait_for_reward = true % Boolean specifying whether to wait for the reward to be given before ending the trial (true) or end the trial immediately (false).
        enable_vis_stim = true % Boolean specifying whether to sent a digital output to the visual stimulus computer to enable the display.
        
        log_trial = false % Boolean specifying whether to log the velocity data for this trial.
        log_fname = '' % Name of the file in which to log the single trial data.
        
        solenoid_correction = 1.55 % How much to correct for voltage differences when solenoid is up or down (mV).
    end
    
    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
    end
    
    properties (Hidden = true)
        ctl % :class:`rc.main.Controller` object controller.
    end

    
    methods
        function obj = Coupled(ctl, config)
            % Constructor for a :class:`rc.prot.Coupled` protocol.
            %
            % :param ctl: :class:`rc.main.Controller` object for interfacing with the stage.
            % :param config: The main configuration file.
        
            obj.ctl = ctl;
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_only';
        end
        
        
        
        function final_position = run(obj)
            % Runs the trial
            %
            % :return: Flag (0/1) indicating trial outcome. 1 indicated the stage moved forward during the trial. 0 Indicates the stage moved backward during the trial or an error occurred.
            %
            % The following procedure is performed:
            %
            % 1. Communicate with the Soloist
            % 2. Block the treadmill (if not already blocked)
            % 3. Send signal to switch off the visual stimulus (if not already off)
            % 4. Load the script in :attr:`direction` to the Teensy (if not already loaded)
            % 5. Save configuration information about the trial
            % 6. Make sure multiplexer is listening to correct source (Teensy)
            % 7. Set TriggerInput to listen to the Soloist input
            % 8. If this is being run as a single trial, play the sound and start NIDAQ acqusition (do not do this if being run as a sequence, as the ProtocolSequence object will handle acquisition and sound)
            % 9. Move the stage to the start position
            % 10. Send signal to the Teensy to disable velocity output while:
            % 11. Analog input offset is measured on the Soloist controller (calibration)
            % 12. Stage is put into gearing (see Soloist.listen_until)
            % 13. Send signal to switch on the visual stimulus (if :attr:`enable_vis_stim` is true)
            % 14. Wait for :attr:`start_dwell_time` seconds
            % 15. Send signal to the Teensy to enable velocity output
            % 16. Unblock the treadmill
            % 17. If :attr:`log_trial` is true, velocity data about this trial is saved
            % 18. Now wait for a trigger from the Soloist indicating that the stage has reached either the backward or forward limit (:attr:`back_limit` / :attr:`forward_limit`). After trigger received:
            % 19. Block the treadmill
            % 20. Send signal to switch off visual stimulus
            % 21. If :attr:`log_trial` is true, stop logging the trial
            % 22. If position is positive (i.e. moved forward) provide a reward
            % 23. If this is being run as a single trial, stop NIDAQ acqusition and sound (do not do this if being run as a sequence, as the ProtocolSequence object will handle acquisition and sound)
            %
            % If error occurs:
            % a. stop any Soloist programs
            % b. Block the treadmill
            % c. Send signal to switch off visual stimulus
            % d. Stop NIDAQ acquisition
            % e. Stop logging the trial
            % f. Stop the sound
            %
            % Stopping of the trial:
            %
            % Only at certain points in execution does the program listen for a stop
            % signal. Therefore, the trial may continue for some time after
            % the `stop` method is run (e.g. when the stage is moving to its
            % start position).
        
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
                obj.ctl.disable_teensy.on();
                obj.ctl.soloist.reset_pso();
                real_time_offset_error = ...
                    obj.ctl.soloist.calibrate_zero(obj.back_limit, obj.forward_limit, 0, [], true); % obj.ctl.soloist.ai_offset
                
                
                % Retrieve the *EXPECTED* offset on the soloist, given the
                % conditions to be used in the task:
                %   solenoid - down
                %   gear mode - on
                %   listening to - Teensy
                %obj.ctl.soloist.ai_offset = obj.ctl.offsets.get_soloist_offset('teensy', 'down', 'on');
                
                % Subtract the residual voltage (if the residual error was
                % positive, we need to subtract it)
                obj.ctl.soloist.ai_offset = -real_time_offset_error + obj.solenoid_correction;%2.3;%obj.ctl.soloist.ai_offset - real_time_offset_error;
                
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
                
                obj.ctl.disable_teensy.off();
                
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
            % Stop the trial.
            % If the stop method is called, the :attr:`abort` property is
            % temporarily set to true. The main loop will detect this and
            % abort properly.
        
            obj.abort = true;
        end
        
        
        function cfg = get_config(obj)
            % Return the configuration information for the trial.
            %
            % :return: An Nx2 cell array with the configuration information about the protocol.
        
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
                    'prot.enable_vis_stim',     sprintf('%i', obj.enable_vis_stim);
                    'prot.initiate_trial',      '---';
                    'prot.initiation_speed',    '---';
                    'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                    'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                    'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                    'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration)};
        end
    
        
        function cleanup(obj)
            % Execute upon stopping or ending the trial.
            % a. Block the treadmill
            % b. Send signal to switchy off visual stimulus
            % c. If :attr:`handle_acquisition` it true, stop any Soloist programs, stop NIDAQ acquisition and stop the sound
            % d. If :attr:`log_trial` is true, stop the logging of single trial data.
        
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
