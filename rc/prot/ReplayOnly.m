classdef ReplayOnly < handle
    % ReplayOnly class for handling trials in which stage is stationary but analog output waveform is used to control e.g. visual stimulus.
    %
    % TODO: make this more general and don't make assumptions about the
    % nature of the data in .bin (e.g. each single trial .bin should have
    % a separate config file).
    %
    % TODO: do not assume that the waveform came from an analog input
    % recording (i.e. don't add an offset here to correct for small
    % differences between AI value and AO value). 

    properties
        start_dwell_time = 5; % Time in seconds to wait at the beginning of the trial.
        start_pos % Position (in Soloist units) at the start of the trial.
        handle_acquisition = true % Boolean specifying whether we are running this as a single trial (true) or as part of a :class:`rc.prot.ProtocolSequence` (false).
        wait_for_reward = true % Boolean specifying whether to wait for the reward to be given before ending the trial (true) or end the trial immediately (false).
        enable_vis_stim = true % Boolean specifying whether to sent a digital output to the visual stimulus computer to enable the display.
        initiate_trial = false; % Boolean specifying whether to let the treadmill velocity initiate the start of the trial.
        initiation_speed = 5; % Speed of the treadmill which initiates the trial (in cm/s).
        
        wave_fname % Full path to the .bin file containing the control waveform to play. Assumed that the .bin file contains a sequence of int16 values which have been transformed from a voltage with the equation int16 val = -2^15 + 2^16 * (voltage + 10)/20 . The int16 value are then transformed back into a voltage to be played on the analog output.
        waveform % # samples x AO channels matrix, voltage waveforms to play on the analog outputs.
        
        direction = 'forward_only' % Direction of travel, (name of Teensy script, e.g. 'forward_only' or 'forward_and_backward').
    end
    
    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
    end
    
    properties (Hidden = true)
        ctl % :class:`rc.main.Controller` object controller.
    end
    
    
    methods
        
        function obj = ReplayOnly(ctl, config, fname)
            % Constructor for a :class:`rc.prot.StageOnly` protocol.
            %
            % :param ctl: :class:`rc.main.Controller` object for interfacing with the stage.
            % :param config: The main configuration file.
            % :param fname: Full path to the .bin file from which to read the waveform data to output on the analog outputs. 
            
            VariableDefault('fname', []);
            
            % main controller object
            obj.ctl = ctl;
            
            % position 
            obj.start_pos = config.stage.start_pos;
            
            % filename containing the data to replay
            obj.wave_fname = fname;
        end
        
        
        
        function load_wave(obj)
            % Loads the waveform from the .bin file, referenced in :attr:`wave_fname`
            
            if isempty(obj.wave_fname); return; end
            
            w = double(read_bin(obj.wave_fname, 1)); % file must be single channel
            
            % store the waveform
            waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;  %#ok<*PROP> %TODO:  config... but StageOnlys shouldn't have to worry about it.
            
            obj.waveform = obj.ctl.offsets.transform_ai_ao_data(waveform, 'up', 'off');
        end
        
        
        
            function final_position = run(obj)
            % Runs the trial
            %
            % :return: Flag (0/1) indicating trial outcome. 1 indicated the stage moved forward during the trial. 0 Indicates the stage moved backward during the trial or an error occurred.
            %
            % The following procedure is performed:
            %
            % 1. The waveform is loaded. If the :attr:`waveform` is empty, we exit the trial.
            % 2. Communicate with the Soloist.
            % 3. Block the treadmill (if not already blocked).
            % 4. Send signal to switch off the visual stimulus (if not already off).
            % 5. Save configuration information about the trial.
            % 6. Make sure multiplexer is listening to correct source (NIDAQ).
            % 7. Set TriggerInput to listen to the Soloist input.
            % 8. Queue the waveform to the analog outputs.
            % 9. If this is being run as a single trial, play the sound and start NIDAQ acqusition (do not do this if being run as a sequence, as the ProtocolSequence object will handle acquisition and sound).
            % 10. Move the stage to the start position.
            % 11. Pause, simulate time taken to calibrate the stage in Coupled class.
            % 12. If :attr:`enable_vis_stim` is true send signal to the visual stimulus to turn on.
            % 13. If :attr:`initiate_trial` is true, unblock the treadmill and wait for the treadmill velocity to reach :attr:`initiation_speed`. TODO: ASSUMES VELOCITY IS ON THE FIRST ANALOG INPUT CHANNEL. When velocity reached, block the treadmill.
            % 14. Wait for :attr:`start_dwell_time` seconds.
            % 15. Start playing the voltage on the analog output.
            % 16. Now wait for the analog output task to finish.
            %
            % After task-finished received:
            %
            % 17. Send signal to switch off visual stimulus.
            % 18. Provide a reward
            % 19. Pause, to simulate time it takes for stage to move back after :class:`rc.prot.Coupled`.
            % 20. If this is being run as a single trial, stop NIDAQ acqusition and sound (do not do this if being run as a sequence, as the ProtocolSequence object will handle acquisition and sound).
            %
            % If error occurs:
            %
            % a. stop any Soloist programs.
            % b. Block the treadmill.
            % c. Send signal to switch off visual stimulus.
            % d. Stop NIDAQ acquisition.
            % e. Stop the sound.
            % f. Switch multiplexer to listen to the Teensy.
            %
            % Stopping of the trial:
            %
            % Only at certain points in execution does the program listen for a stop
            % signal. Therefore, the trial may continue for some time after
            % the `stop` method is run (e.g. when the stage is moving to its
            % start position).
        
            try
                
                % times simulating features of other protocols
                %   calibration time + connection to soloist (~6s)
                %   moveback of stage from one end to other (~7s)
                simulate_calibration_s = 6;
                simulate_moveback = 7;
                
                % always assume it has finished in positive direction
                final_position = 1;
                
                % load waveform to play
                obj.load_wave();
                
                % if there is no waveform, don't do anything
                if isempty(obj.waveform)
                    final_position = 0;
                    warning('NO WAVEFORM LOADED, SKIPPING PROTOCOL\n')
                    return
                end
                
                % we are now running
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
              
                % startup initial communication
                proc = obj.ctl.soloist.communicate();
                proc.wait_for(0.5);
                
                % if this protocol is handling the acquisition, prepare for
                % acquisition
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                % make sure the treadmill is blocked
                obj.ctl.block_treadmill();
                
                % switch vis stim off
                obj.ctl.vis_stim.off();
                
                % get and save config for this protocol
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to correct source
                obj.ctl.multiplexer.listen_to('ni');
                
                % start PC listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('soloist');
                
                % load the velocity waveform to NIDAQ
                obj.ctl.load_velocity_waveform(obj.waveform);
                
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % start the move to operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
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
                
                % let animal initiate the trial
                if obj.initiate_trial
                    
                    obj.ctl.unblock_treadmill();
                    
                    fprintf('waiting for trial initialization\n');
                    
                    while all(obj.ctl.tdata(:, 1) < obj.initiation_speed)
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    
                    obj.ctl.block_treadmill();
                else
                    % This is frustrating: we need some indication of the
                    % start of the trial and the change in solenoid state
                    % is being used.
                    % Should be replaced with a dedicated start trigger?
                    obj.ctl.unblock_treadmill();
                    pause(0.1);
                    obj.ctl.block_treadmill();
                end
                
                % wait start_dwell_time seconds
                tic;
                while toc < obj.start_dwell_time
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % start playing the waveform
                obj.ctl.play_velocity_waveform()
                
                % check to see AO is still running
                while obj.ctl.ni.ao.task.IsRunning
                    
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % if AO no longer running set voltage waveform to the idle value
                obj.ctl.set_ni_ao_idle('up', 'off');
                
                % switch vis stim off
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.off();
                end
                
                % wait for reward to complete then stop acquisition
                obj.ctl.reward.start_reward(obj.wait_for_reward)
                
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
                obj.ctl.stop_sound();
                
                obj.ctl.multiplexer.listen_to('teensy');
                obj.ctl.set_ni_ao_idle('up', 'off');
                
                rethrow(ME)
            end
        end
        
        
        function stop(obj)
            % Stop the trial.
            %
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
                    'prot.back_limit',          '---';
                    'prot.forward_limit',       '---';
                    'prot.direction',           '---';
                    'prot.start_dwell_time',    sprintf('%.3f', obj.start_dwell_time);
                    'prot.handle_acquisition',  sprintf('%i', obj.handle_acquisition);
                    'prot.wait_for_reward',     sprintf('%i', obj.wait_for_reward);
                    'prot.log_trial',           '---';
                    'prot.log_fname',           '---';
                    'prot.integrate_using',     '---';
                    'prot.wave_fname',          obj.wave_fname;
                    'prot.enable_vis_stim',     sprintf('%i', obj.enable_vis_stim);
                    'prot.initiate_trial',      sprintf('%i', obj.initiate_trial);
                    'prot.initiation_speed',    sprintf('%i', obj.initiation_speed);
                    'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                    'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                    'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                    'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration)};
        end
        
        
        function cleanup(obj)
            % Execute upon stopping or ending the trial
            % a. Block the treadmill
            % b. Send signal to switch off visual stimulus
            % c. If :attr:`handle_acquisition` is true, stop any Soloist programs, stop NIDAQ acquisition and stop the sound.
            % d. Switch multiplexer to listen to the Teensy.
            
            obj.running = false;
            obj.abort = false;
            
            obj.ctl.block_treadmill()
            obj.ctl.vis_stim.off();
            obj.ctl.position.stop();
            
            if obj.handle_acquisition
                obj.ctl.soloist.stop();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
                %TODO: stop waveform running
            end
            
            obj.ctl.multiplexer.listen_to('teensy');
            obj.ctl.set_ni_ao_idle('up', 'off');
        end
    end
end