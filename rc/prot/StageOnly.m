classdef StageOnly < handle
% StageOnly Class for handling trials in which the linear stage is
% controlled by a waveform
%
%   StageOnly Properties:
%       start_dwell_time        - time in seconds to wait at the beginning of the trial
%       start_pos               - position (in Soloist units) at the start of the trial 
%       back_limit              - backward position beyond which the trial is stopped
%       forward_limit           - foreward position beyond which the trial is stopped and reward given
%       direction               - direction of travel (name of Teensy script, e.g. 'forward_only' or 'forward_and_backward')
%       handle_acquisition      - whether we are running this as a single trial (true) or as part of a sequence (false)
%       wait_for_reward         - whether to wait for the reward to be
%                                 given before ending the trial (true) or
%                                 end the trial immediately (false)
%       enable_vis_stim         - whether to send a digital output to the
%                                 visual stimulus computer to enable the
%                                 display (true = enable, false = disable)
%       initiate_trial          - whether to let the treadmill velocity initiate the start of the trial
%       initiation_speed        - speed of treadmill which initiates the trial (in cm/s)
%       wave_fname              - full path to the .bin file containing the
%                                 waveform to play
%
%     For internal use:
%
%       waveform                - # samples x # AO channels matrix, voltage
%                                 waveforms to play on the analog outputs
%       running                 - whether the trial is currently running
%                                 (true = running, false = not running)
%
%   StageOnly Methods:
%       load_wave               - loads the waveform from the .bin file
%       run                     - run the trial
%       stop                    - stop the trial
%       get_config              - return configuration information for the trial
%
%
%   Important:
%
%       Currently the waveform to send to the Soloist is read from a .bin
%       file, which is assumed to contain single channel of data
%  
%       It is assumed that the .bin file contains a sequence of int16
%       values which have been transformed from a voltage with the equation
%           int16 val = -2^15 + 2^16 * (voltage + 10)/20;
%       i.e. range -10 to 10
%
%       The int16 value are then transformed back into a voltage to be
%       played on the analog output.
%
%   TODO: make this more general and don't make assumptions about the
%   nature of the data in .bin (e.g. each single trial .bin should have
%   a separate config file).
%
%   TODO: do not assume that the waveform came from an analog input
%   recording (i.e. don't add an offset here to correct for small
%   differences between AI value and AO value). 
%
%   TODO: remove `log_trial` and associated parts of the code
%
%   See also: StageOnly, run

    properties
        
        start_dwell_time = 5;
        start_pos
        back_limit
        forward_limit
        direction
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        initiate_trial = false;
        initiation_speed = 5;
        
        wave_fname
        waveform
        
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
        
        function obj = StageOnly(ctl, config, fname)
        % StageOnly
        %
        %   StageOnly(CTL, CONFIG, FILENAME) creates object handling trials
        %   in which the linear stage velocity is controlled by a waveform.
        %   CTL is an object of class RC2Controller, giving 
        %   access to the setup and CONFIG is the main configuration
        %   structure for the setup.
        %
        %   FILENAME is the full path to the .bin file from which to read
        %   the waveform data to output on the analog outputs. It is
        %   optional, but if omitted, the `wave_fname` property should be
        %   set to a full path after object creation.
        %
        %   See also: run
        
            VariableDefault('fname', []);
            
            obj.ctl = ctl;
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_only';
            obj.wave_fname = fname;
        end
        
        
        
        function load_wave(obj)
        %%load_wave Loads the waveform from the .bin file    
        %
        %   load_wave() loads the waveform contained in `wave_fname`. See
        %   the `Important` section in the main class documentation about
        %   the assumed nature of the .bin file.
        
            if isempty(obj.wave_fname); return; end
            
            w = double(read_bin(obj.wave_fname, 1)); % file must be single channel
            
            waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;  %#ok<*PROP> %TODO:  config... but StageOnlys shouldn't have to worry about it.
            
            % Transform the waveform according to the state of the setup
            % during the task:
            %   solenoid - up
            %   gear_mode - on
            obj.waveform = obj.ctl.offsets.transform_ai_ao_data(waveform, 'up', 'on');
        end
        
        
        
        function final_position = run(obj)
        %%run Runs the trial
        %
        %   MOVED_FORWARD = run() runs the trial. MOVED_FORWARD is either 0
        %   or 1 - 1 indicates the stage moved forward during the trial, 0
        %   indicates that the stage moved backward during the trial or
        %   an error occurred.
        %
        %   Following procedure is performed:
        %
        %       1. The waveform is loaded
        %           If the `waveform` is empty, we exit the trial
        %       2. Communicate with the Soloist
        %       3. Block the treadmill (if not already blocked)
        %       4. Send signal to switch off the visual stimulus (if not already off)
        %       5. Save configuration information about the trial
        %       6. Make sure multiplexer is listening to correct source (NIDAQ)
        %       7. Set TriggerInput to listen to the Soloist input
        %       8. Queue the waveform to the analog outputs
        %       9. If this is being run as a single trial, play the sound and start NIDAQ
        %       acqusition (do not do this if being run as a sequence, as
        %       the ProtocolSequence object will handle acquisition and
        %       sound)
        %       10. Move the stage to the start position
        %       11. Send signal to the Teensy to disable velocity output
        %       while:
        %       12. Analog input offset is measured on the Soloist
        %       controller (calibration)
        %       13. If `enable_vis_stim` is true send signal to the visual
        %       stimulus to turn on 
        %       14. If `initiate_trial` is true, unblock the treadmill and
        %       wait for the treadmill velocity to reach `initiation_speed`
        %           TODO: ASSUMES VELOCITY IS ON THE FIRST ANALOG INPUT CHANNEL
        %       When velocity reached, block the treadmill
        %       15. Stage is put into gearing (see
        %       Soloist.listen_until)
        %       16. Wait for `start_dwell_time` seconds
        %       17. Start playing the voltage on the analog output
        %       18. Now wait for a trigger from the Soloist indicating that
        %       the stage has reached either the backward or forward limit
        %       (`back_limit`/`forward_limit`)
        %       If the AO finishes before the trigger is received, then
        %       send a linear increasing ramp voltage from the AO until the
        %       trigger from the Soloist is received (see
        %       RC2Controller.ramp_velocity).
        %       After trigger received:
        %           19. Send signal to switch off visual stimulus
        %           20. Provide a reward
        %           21. If this is being run as a single trial, stop NIDAQ
        %           acqusition and sound (do not do this if being run as a sequence, as
        %           the ProtocolSequence object will handle acquisition and
        %           sound)
        %           22. Switch multiplexer to listen to the Teensy
        %
        %       If error occurs:
        %           a. stop any Soloist programs
        %           b. Block the treadmill
        %           c. Send signal to switch off visual stimulus
        %           d. Stop NIDAQ acquisition
        %           e. Stop the sound
        %           f. Switch multiplexer to listen to the Teensy
        %
        %
        %   Stopping of the trial:
        %
        %       Only at certain points in execution does the program listen for a stop
        %       signal. Therefore, the trial may continue for some time after
        %       the `stop` method is run (e.g. when the stage is moving to its
        %       start position).
        
            try
                
                % always assume it has finished in positive direction
                final_position = 1;
                
                % load the waveform to be played
                obj.load_wave();
                
                if isempty(obj.waveform)
                    final_position = 0;
                    fprintf('NO WAVEFORM LOADED, SKIPPING\n')
                    return
                end
                
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
                
                % switch vis stim off
                obj.ctl.vis_stim.off();
                
                % get and save config
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to correct source
                obj.ctl.multiplexer_listen_to('ni');
                
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
                
                % Retrieve the *EXPECTED* offset on the soloist, given the
                % current conditions and a prior calibration value:
                %   solenoid - up
                %   gear mode - off
                %   listening to - NI
                % obj.ctl.soloist.ai_offset = obj.ctl.offsets.get_soloist_offset('ni', 'up', 'off');
                
                % Apply the voltage on the NI matching these conditions
                obj.ctl.set_ni_ao_idle('up', 'off');
                
                % Get the *CURRENT* error on the soloist when that expected
                % voltage is applied.
                % This line applies the *EXPECTED* offset on the soloist and returns 
                % the residual error
                obj.ctl.disable_teensy.on();
                obj.ctl.soloist.reset_pso();
                real_time_offset_error = ...
                    obj.ctl.soloist.calibrate_zero(obj.back_limit, obj.forward_limit, 0, [], true); % obj.ctl.soloist.ai_offset
                obj.ctl.disable_teensy.off();
                
                % Retrieve the *EXPECTED* offset on the soloist, given the
                % conditions to be used in the task:
                %   solenoid - up
                %   gear mode - on
                %   listening to - Teensy
                %obj.ctl.soloist.ai_offset = obj.ctl.offsets.get_soloist_offset('ni', 'up', 'on');
                
                % Subtract the residual voltage (if the residual error was
                % positive, we need to subtract it)
                %obj.ctl.soloist.ai_offset = obj.ctl.soloist.ai_offset - real_time_offset_error;
                obj.ctl.soloist.ai_offset = -real_time_offset_error;%obj.ctl.soloist.ai_offset - real_time_offset_error;
                
                
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
                
                % the soloist will connect, setup some parameters and then
                % wait for the solenoid signal to go low
                % we need to give it some time to setup (~2s, but we want
                % to wait at the start position anyway...
                % don't wait for trigger
                obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit, false);
                
                % Reset the idle voltage on the NI as we are now in gear
                % mode
                obj.ctl.set_ni_ao_idle('up', 'on');
                
                % start integrating position
                obj.ctl.position.start();
                
                % wait at the start
                tic;
                while toc < obj.start_dwell_time
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % start logging the single trial
                if obj.log_trial
                    obj.ctl.start_logging_single_trial(obj.log_fname);
                end
                
                % start playing the waveform
                obj.ctl.play_velocity_waveform()
                
                % look out for the waveform finishing, but the trigger not
                % being received
                premature_end = false;
                
                % wait for process to terminate.
                while ~obj.ctl.trigger_input.read()
                    
                    % check to see AO is still running
                    if ~obj.ctl.ni.ao.task.IsRunning
                        
                        % if AO no longer running set voltage waveform to the idle value
                        obj.ctl.set_ni_ao_idle('up', 'on');
                        
                        premature_end = true;
                        break
                    end
                    
                    % TODO: if waveform has stopped break out of the loop
                    % otherwise will hang forever...
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % if there was a premature end of the trial play a voltage
                % ramp
                if premature_end
                    fprintf('playing voltage ramp\n');
                    obj.ctl.ramp_velocity();
                end
                
                % this time we should definitely get to the end
                while ~obj.ctl.trigger_input.read()
                    
                    % TODO: if waveform has stopped break out of the loop
                    % otherwise will hang forever...
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
                
                % stop integrating position
                obj.ctl.position.stop();
                
                % stop logging the single trial.
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % wait for reward to complete then stop acquisition
                obj.ctl.reward.start_reward(obj.wait_for_reward)
                
                % if handling the acquisition stop 
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
                obj.ctl.soloist.reset_pso();
                obj.ctl.multiplexer.listen_to('teensy');
                
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
                obj.ctl.multiplexer.listen_to('teensy');
                obj.ctl.set_ni_ao_idle('up', 'off');
                
                rethrow(ME)
            end
        end
        
        
        
        function stop(obj)
        %%stop Stop the trial
        %
        %   stop()
        %   if the stop method is called, the `abort` property is
        %   temporarily set to true. The main loop will detect this and
        %   abort properly 
        
            obj.abort = true;
        end
        
        
        
        function cfg = get_config(obj)
        %%get_config Return the configuration information for the trial
        %
        %   CONFIG = get_config() returns a Nx2 cell array with
        %   configuration information about the protocol.
        %
        %   See also: RC2Controller.get_config, Saver.save_config
        
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
        %%cleanup Execute upon stopping or ending the trial
        %
        %   cleanup() upon finishing the run method the following is
        %   executed:
        %
        %           a. Block the treadmill
        %           b. Send signal to switch off visual stimulus
        %           c. If `handle_acquisition` is true, stop any Soloist
        %              programs, stop NIDAQ acquisition and stop the sound
        %           d. Switch multiplexer to listen to the Teensy
        
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
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
            
            obj.ctl.multiplexer.listen_to('teensy');
            obj.ctl.set_ni_ao_idle('up', 'off');
        end
    end
end
