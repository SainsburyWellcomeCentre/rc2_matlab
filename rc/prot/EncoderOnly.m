classdef EncoderOnly < handle
    % EncoderOnly class for handling trials in which the stage is stationary but the treadmill is allowed to move a certain distance.
    
    properties
        start_dwell_time = 5 % Time in seconds to wait at the beginning of the trial.
        stage_pos % Position (in Soloist units) of the stage for the whole trial.
        back_limit % Backward position beyond which the trial is stopped.
        forward_limit % Forward position beyond which the trial is stopped and reward given.
        direction % Direction of travel (name of Teensy script, e.g. 'forward_only' or 'forward_and_backward').
        handle_acquisition = true % Boolean specifying whether we are running this as a single trial (true) or as part of a :class:`rc.prot.ProtocolSequence` (false).
        wait_for_reward = true % Boolean specifying whether to wait for the reward to be given before ending the trial (true) or end the trial immediately (false).
        enable_vis_stim = true % Boolean specifying whether to sent a digital output to the visual stimulus computer to enable the display.
        
        log_trial = false % Boolean specifying whether to log the velocity data for this trial.
        log_fname = '' % Name of the file in which to log the single trial data.
        
        integrate_using = 'pc' % Indicates whether to use the position from the PC via a :class:`rc.classes.Position` class or from the Teensy to determine position. If using 'teensy' the trial will wait for a trigger from the Teensy before stopping. Otherwise it listens to the `position` variable of the :class:`rc.classes.Position` to determine trial end. 'teensy' or 'pc'.
    end
    
    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
    end
    
    properties (Hidden = true)
        ctl % :class:`rc.main.RC2Controller` object controller.
    end
    
    properties (Dependent = true)
        distance_forward
        distance_backward
    end
    
    
    methods
        
        function obj = EncoderOnly(ctl, config)
            % Constructor for a :class:`rc.prot.EncoderOnly` protocol.
            %
            % :param ctl: :class:`rc.main.RC2Controller` object for interfacing with the stage.
            % :param config: The main configuration file.
        
            obj.ctl = ctl;
            
            % forward and backward positions as if on the stage
            obj.stage_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            
            obj.direction = 'forward_only';
        end
        
        
        function val = get.distance_forward(obj)
            % Amount of distance, in mm, to move forward before stopping the trial.
        
            val = obj.stage_pos - obj.forward_limit;
        end
        
        
        
        function val = get.distance_backward(obj)
            % Amount of distance, in mm, to move backward before stopping the trial.
        
            val = obj.stage_pos - obj.back_limit;
        end
        
        
        
        function final_position = run(obj)
            % Runs the trial
            %
            % :return: Flag (0/1) indicating trial outcome. 1 indicated the treadmill moved forward during the trial. 0 Indicates the treadmill moved backward during the trial or an error occurred.
            %
            % The following procedure is performed:
            %
            % 1. Communicate with the Soloist
            % 2. Block the treadmill (if not already blocked)
            % 3. Send signal to switch off the visual stimulus (if not already off)
            % 4. Load the script in :attr:`direction` to the Teensy (if not already loaded)
            % 5. Save configuration information about the trial
            % 6. Make sure multiplexer is listening to correct source (Teensy)
            % 7. If :attr:`integrate_using` is 'teensy', set TriggerInput to listen to the Teensy input
            % 8. If this is being run as a single trial, play the sound and start NIDAQ acqusition (do not do this if being run as a sequence, as the ProtocolSequence object will handle acquisition and sound)
            % 9. Move the stage to the start position
            % 10. Pause, simulate amount of time in Coupled for calibrating the stage
            % 11. Send signal to switch on the visual stimulus (if :attr:`enable_vis_stim` is true)
            % 12. Wait for :attr:`start_dwell_time` seconds
            % 13. Send signal to the Teensy to enable velocity output
            % 14. Unblock the treadmill
            % 15. If :attr:`log_trial` is true, velocity data about this trial is saved
            % 16. Now wait for end of trial. If :attr:`integrate_using` is 'teensy' it will wait for a trigger from the Teensy. If set to 'pc' it will wait for the position variable in the Position (`position` property in :class:`rc.main.RC2Controller` object) to read the trial bounds.
            % 17. Block the treadmill
            % 18. Send signal to switch off visual stimulus
            % 19. If :attr:`log_trial` is true, stop logging the trial
            % 20. If position is positive (i.e. moved forward) provide a reward
            % 21. Pause, simulate amount of time after a :class:`rc.prot.Coupled` trial for the stage to move back
            % 22. If this is being run as a single trial, stop NIDAQ acqusition and sound (do not do this if being run as a sequence, as the :class:`rc.prot.ProtocolSequence` object will handle acquisition and sound)
            %
            % If error occurs:
            % a. stop any Soloist programs
            % b. Block the treadmill
            % c. Send signal to switch off visual stimulus
            % d. Stop NIDAQ acquisition
            % e. Stop logging the trial
            % f. Stop the sound
            %
            %
            % Stopping of the trial:
            % Only at certain points in execution does the program listen for a stop signal. Therefore, the trial may continue for some time after the `stop` method is run (e.g. when the stage is moving to its position).
        
            try
               
                % times simulating features of other protocols
                %   calibration time + connection to soloist (~6s)
                %   moveback of stage from one end to other (~7s)
                simulate_calibration_s = 6;
                simulate_moveback = 7;
                
                % report the end position
                final_position = 0;
                
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % startup initial communication
                proc = obj.ctl.soloist.communicate();
                proc.wait_for(0.5);
                
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                % make sure the treadmill is blocked
                obj.ctl.block_treadmill();
                
                % make sure vis stim is off
                obj.ctl.vis_stim.off();
                
                % prevent output of the teensy until just before the trial
                obj.ctl.disable_teensy.on();
                
                % load correct direction on teensy
                obj.ctl.teensy.load(obj.direction);
                
                
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to correct source
                obj.ctl.multiplexer_listen_to('teensy');
                
                % start listening to the correct trigger input
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.trigger_input.listen_to('teensy');
                end
                
                % start acquiring data if the protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % move to position along stage where the trial will take
                % place
                proc = obj.ctl.soloist.move_to(obj.stage_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                
                % if we are using the teensy to determine position reset
                % the position onboard teensy
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.reset_teensy_position();
                end
                
                 % we want to reset the position anyway
                obj.ctl.reset_pc_position();
                
                % simulate the calibration
                tic;
                while toc < simulate_calibration_s
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % switch vis stim on
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.on();
                else
                    obj.ctl.vis_stim.off();
                end
                
                
                % start integrating the position
                obj.ctl.position.start();
                
                % wait a bit of time before starting the trial
                tic;
                while toc < obj.start_dwell_time
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % enable the teensy again
                obj.ctl.disable_teensy.off();
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging velocity if required.
                if obj.log_trial
                    obj.ctl.start_logging_single_trial(obj.log_fname);
                end
                
                if strcmp(obj.integrate_using, 'teensy')
                    
                    % wait for the trigger from the teensy
                    while ~obj.ctl.trigger_input.read()
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    
                else
                    
                    % integrate position on PC until the bounds are reached
                    forward_cm = obj.distance_forward/10;
                    backward_cm = obj.distance_backward/10;
                    
                    obj.ctl.position.start();
                    while obj.ctl.position.position < forward_cm && obj.ctl.position.position > backward_cm
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    obj.ctl.position.stop();
                end
                
                % add 500ms to end of trial (= gain change time on soloist)
                tic;
                while toc < 0.5
                    pause(0.005);
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % switch vis stim off
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.off();
                end
                
                % stop integrating position
                obj.ctl.position.stop();
                
                % stop logging single trial
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % make sure the stage has moved foward before giving reward
                if obj.ctl.get_position() > 0
                    final_position = 1;
                    % start reward, block until finished if necessary
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
                end
                
                % simulate moveback of the stage
                tic;
                while toc < simulate_moveback
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % stop acquiring data if protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
                % the protocol is no longer running
                obj.running = false;
                
            catch ME
                
                % if an error has occurred, perform the following whether
                % or not the singple protocol is handling the acquisition
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
                'prot.start_pos',           '---';
                'prot.stage_pos',           sprintf('%.3f', obj.stage_pos);
                'prot.back_limit',          sprintf('%.3f', obj.back_limit);
                'prot.forward_limit',       sprintf('%.3f', obj.forward_limit);
                'prot.direction',           obj.direction;
                'prot.start_dwell_time',    sprintf('%.3f', obj.start_dwell_time);
                'prot.handle_acquisition',  sprintf('%i', obj.handle_acquisition);
                'prot.wait_for_reward',     sprintf('%i', obj.wait_for_reward);
                'prot.log_trial',           sprintf('%i', obj.log_trial);
                'prot.log_fname',           sprintf('%s', obj.log_fname);
                'prot.integrate_using',     obj.integrate_using;
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
            
            fprintf('running cleanup in encoder\n')
            
            obj.ctl.block_treadmill();
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
