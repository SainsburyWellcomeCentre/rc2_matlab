classdef Controller < handle
    % Main class for interfacing with the rollercoaster setup.

    properties
        ni % :class:`rc.nidaq.NI`
        teensy % :class:`rc.dev.Teensy`
        soloist % :class:`rc.dev.Soloist`
        pump % :class:`rc.dev.Pump`
        reward % :class:`rc.actions.Reward`
        treadmill % :class:`rc.actions.Treadmill`
        multiplexer % :class:`rc.actions.Multiplexer`
        plotting % :class:`rc.aux_.Plotting`
        saver % :class:`rc.saving.Saver`
        sound % :class:`rc.dev.Sound`
        threat_sound % :class:`rc.dev.TimedSound`
        threat_sound_play_time % Time in seconds to play the threat sound when triggered
        position % :class:`rc.aux_.Position`
        zero_teensy % :class:`rc.actions.ZeroTeensy`
        disable_teensy % :class:`rc.actions.DisableTeensy`
        trigger_input % :class:`rc.actions.TriggerInput`
        data_transform % :class:`rc.aux_.DataTransform`
        vis_stim % :class:`rc.actions.VisStim`
        start_soloist % :class:`rc.actions.StartSoloist`
        offsets % :class:`rc.aux_.Offsets`
        teensy_gain % :class:`rc.actions.TeensyGain`
        delayed_velocity % :class:`rc.actions.DelayedVelocity`
        data % Data matrix with latest voltage data.
        tdata % Data matrix with transformed data.
        timeout_seconds; % Trial timeout length in seconds.
    end
    
    
    properties (SetObservable = true, SetAccess = private, Hidden = true)
        acquiring = false % Boolean specifying whether we are currently acquiring data.
        acquiring_preview = false; % Boolean specifying whether we are currently acquiring preview data.
    end
    
    
    methods
        
        function obj = Controller(config)
            % Constructor for a :class:`rc.main.Controller` RC2 Controller.
            %
            % :param config: The main configurations structure.
        
            obj.ni = NI(config);
            obj.teensy = Teensy(config);
            obj.soloist = Soloist(config);
            obj.pump = Pump(obj.ni, config);
            obj.reward = Reward(obj.pump, config);
            obj.treadmill = Treadmill(obj.ni, config);
            obj.multiplexer = Multiplexer(obj.ni, config);
            obj.plotting = Plotting(config);
            obj.sound = Sound();
            obj.threat_sound = TimedSound(config);
            obj.threat_sound_play_time = config.sound.threat_sound_play_time;
            obj.position = Position(config);
            obj.saver = Saver(obj, config);
            obj.data_transform = DataTransform(config);
            obj.offsets = Offsets(obj, config);
            obj.delayed_velocity = DelayedVelocity(obj.ni, config);
            
            % Triggers
            obj.zero_teensy = ZeroTeensy(obj.ni, config);
            obj.disable_teensy = DisableTeensy(obj.ni, config);
            obj.trigger_input = TriggerInput(obj.ni, config);
            obj.vis_stim = VisStim(obj.ni, config);
            obj.start_soloist = StartSoloist(obj.ni, config);
            obj.teensy_gain = TeensyGain(obj.ni, config);
            
            % Timeouts
            obj.timeout_seconds = config.timeout.timeout_seconds;
        end
        
        
        function delete(obj)
            % Destructor for :class:`rc.main.Controller`.
        
            delete(obj.plotting);
            
            % make sure that all devices are stopped properly
            obj.soloist.abort()
            obj.sound.stop()
            obj.stop_acq()
            obj.ni.close()
        end
        
        
        function start_preview(obj)
            % Start previewing and displaying analog input data.
        
            % if we are already acquiring don't do anything.
            if obj.acquiring_preview || obj.acquiring; return; end
            
            % setup the NI-DAQ device for plotting
            obj.ni.prepare_acq(@(x, y)obj.h_preview_callback(x, y))
            
            % reset all display options
            obj.plotting.reset_vals();
            
            % start the NI-DAQ device and set acquiring flag to true
            obj.ni.start_acq(false);  % false indicates not to start clock
            obj.acquiring_preview = true;
        end
        
        
        function stop_preview(obj)
            % Stop previewing and displaying analog input data.
        
            % if we are not acquiring preview don't do anything.
            if ~obj.acquiring_preview; return; end
            % if we are acquiring and saving don't do anything
            if obj.acquiring; return; end
            
            % set acquring flag to false and stop NI-DAQ
            obj.acquiring_preview = false;
            obj.ni.stop_acq(false);  % false indicates that clock is not on.
        end
        
        
        function h_preview_callback(obj, ~, evt)
            % Callback function for previewing data.
        
            % store the current data
            obj.data = evt.Data;
            
            % transform data
            obj.tdata = obj.data_transform.transform(obj.data);
            
            % pass transformed data to plotter
            obj.plotting.ni_callback(obj.tdata);
        end
        
        
        function prepare_acq(obj)
            % Prepare for main acquisiton of data.
            % Setup files in which to save data and config information, prepare nidaq for acquisition and reset display.
            % TODO: this should be called by start_acq()
        
            if obj.acquiring || obj.acquiring_preview
                error('already acquiring data')
                return %#ok<UNRCH>
            end
            
            obj.saver.setup_logging();
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            obj.plotting.reset_vals();
        end
        
        
        function start_acq(obj)
            % Start acquiring and displaying data.
        
            % if already acquiring don't do anything
            if obj.acquiring || obj.acquiring_preview; return; end
            
            % start the NI-DAQ device and set acquiring flag to true
            obj.ni.start_acq()
            obj.acquiring = true;
        end
        
        
        function h_callback(obj, ~, evt)
            % Callback function for acquiring data.
            % Responsible for saving data, transforming into sensible units, plotting the data, integrating velocity trace to estimate position of the stage.
            % TODO: Currently passes the first column of the data matrix to the Position class to estimate position. This will break if first column is not a velocity trace.
        
            % store the data so others can use it
            obj.data = evt.Data;
            
            % log raw voltage
            obj.saver.log(evt.Data);
            
            % transform data
            obj.tdata = obj.data_transform.transform(evt.Data);
            
            % pass transformed data to callbacks
            obj.plotting.ni_callback(obj.tdata);
            obj.position.integrate(obj.tdata(:, 1));  % TODO
        end
        
        
        function stop_acq(obj)
            % Stop acquiring and displaying data.
        
            if ~obj.acquiring; return; end
            if obj.acquiring_preview; return; end
            
            obj.acquiring = false;
            obj.ni.stop_acq();
            obj.saver.stop_logging();
        end
        
        
        function play_sound(obj)
            % Play the defined controller sound.
        
            obj.sound.play()
        end
        
        function stop_sound(obj)
            % Stop the controller defined sound.
        
            obj.sound.stop()
        end
        
        function play_threat(obj)
            % Starts the thread sound looping for config defined length of
            % time
           obj.threat_sound.play_for(obj.threat_sound_play_time); 
        end
        
        function stop_threat(obj)
            % Force stops the threat sound
            obj.threat_sound.stop();
        end
        
        function give_reward(obj)
            % Give a reward.
        
            % obj.reward.give_reward();
            obj.reward.start_reward(0)
        end
        
        
        function block_treadmill(obj, gear_mode)
            % Block the treadmill.
        
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.block()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('up', gear_mode);
            end
        end
        
        
        function unblock_treadmill(obj, gear_mode)
            % Unblock the treadmill.
        
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.unblock()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('down', gear_mode);
            end
        end
        
        
        function pump_on(obj)
            % Turn the pump on.
        
            obj.pump.on()
        end
         
        
        function pump_off(obj)
            % Turn the pump off.
        
            obj.pump.off()
        end
        
        
        function move_to(obj, pos, speed, leave_enabled)
            % Move the linear stage to a position.
            %
            % :param pos: The position to move to (in Soloist controller units).
            % :param speed: Movement speed (in Soloist controller units).
            % :param leave_enabled: Boolean specifying whether to leave the stage enabled after the move has been made (true) or disable after the move (false).
        
            VariableDefault('speed', obj.soloist.default_speed);
            VariableDefault('leave_enabled', false);
            
            obj.soloist.move_to(pos, speed, leave_enabled);
        end
        
        
        function home_soloist(obj)
            % Home the Soloist.
        
            obj.soloist.home();
        end
        
        
        function ramp_velocity(obj)
            % Ramp the velocity on the soloist.
            %
            % Creates a 1s linear ramped waveform from :meth:`rc.nidaq.AnalogOutput.idle_offset` to `rc.nidaq.AnalogOutput.idle_offset` + :attr:`rc.dev.Soloist.v_per_cm_per_s`
            % and loads + plays this on the analog output. 
            % The final voltage will remain on the analog output at the end of the ramp, so user should be careful to reset the analog output if this is used.
        
            % create a 1s ramp to 10mm/s
            rate = obj.ni.ao.task.Rate;
            ramp = obj.soloist.v_per_cm_per_s * (0:rate-1) / rate;
            
            % use the first idle_offset value. we are assuming the ONLY use
            % case for other analog channels is for a delayed copy of the
            % velocity waveform...
            waveform = obj.ni.ao.idle_offset(1) + ramp';
            obj.load_velocity_waveform(waveform);
            pause(0.1);
            obj.play_velocity_waveform();
        end
        
        
        function load_velocity_waveform(obj, waveform)
            % Load a velocity waveform to the nidaq.
            % If there is a delayed copy to be output on the second analog output, the waveform will be duplicated with the :class:`rc.actions.DelayedVelocity` class.
            % In this case, the waveform provided here should be single dimensional. 
        
            if obj.delayed_velocity.enabled
                waveform = obj.delayed_velocity.create_waveform(waveform);
            end
            
            % write a waveform (in V)
            obj.ni.ao_write(waveform);
        end
    
        
        function play_velocity_waveform(obj)
            % Play the velocity waveform loaded on the nidaq.
        
            obj.ni.ao_start();
        end
        
        
        function set_save_save_to(obj, str)
            % Set the save to directory.
            %
            % :param str: The main directory in which to save data. .bin files are saved in the form <save_to_dir>\<prefix>\<prefix_suffix_index>.bin.
        
            if obj.acquiring; return; end
            obj.saver.set_save_to(str)
        end
        
        
        function set_save_prefix(obj, str)
            % Set the save file prefix
            %
            % :param str: The save file prefix. .bin files are saved in the form <save_to_dir>\<prefix>\<prefix_suffix_index>.bin.
        
            if obj.acquiring; return; end
            obj.saver.set_prefix(str)
        end
        
        
        function set_save_suffix(obj, str)
            % Set the save file suffix.
            %
            % :param str: The save file suffix. .bin files are saved in the form <save_to_dir>\<prefix>\<prefix_suffix_index>.bin.
        
            if obj.acquiring; return; end
            obj.saver.set_suffix(str)
        end
        
        
        
        function set_save_index(obj, val)
            % Set the save file index.
            %
            % :param val: The save file index. .bin files are saved in the form <save_to_dir>\<prefix>\<prefix_suffix_index>.bin.
        
            if obj.acquiring; return; end
            obj.saver.set_index(val)
        end
        
        
        function set_save_enable(obj, val)
            % Enable the saving of files.
            %
            % :param val: Boolean specifying whether to save (true) or not (false).
        
            if obj.acquiring; return; end
            obj.saver.set_enable(val)
        end
        
        
        function fid = start_logging_single_trial(obj, fname)
            % Save the velocity for a single trial.
            %
            % :param fname: Full path to the file in which to log the data.
            % :return: Integer file identifier.
        
            % open file for saving
            fid = obj.saver.start_logging_single_trial(fname);
            
            % throw warning if file couldn't be opened
            if fid == -1
                warning('Not logging single trial. Specified file name: %s', fname);
            end
        end
        
        
        function save_single_trial_config(obj, cfg)
            % Save config for a single trial.
            %
            % :param cfg: Configuration information to the append to the main configuration file for acquisition.
        
            obj.saver.append_config(cfg);
        end
        
        
        function stop_logging_single_trial(obj)
            % Stop logging a single trial. Closes files associated with logging single trial / short segments of the main acquisition.
        
            obj.saver.stop_logging_single_trial()
        end
        
        
        function reset_pc_position(obj)
            % Reset position. Not in use.

            %obj.position.reset();
        end
        
        
        function reset_teensy_position(obj)
            % Reset the internal Teensy position to zero.
        
            obj.zero_teensy.zero();
        end
        
        
        function pos = get_position(obj)
            % Get the current position value from the :attr:`position` object.
            %
            % :return: Position value.
        
            pos = obj.position.position;
        end
        
        
        function set_ni_ao_idle(obj, solenoid_state, gear_mode)
            % Set the :attr:`ni` AO to its idle voltage.
            %
            % :param solenoid_state: The current state of the solenoid ('up' or 'down').
            % :param gear_mode: The current Soloist gear mode ('on' or 'off').
        
            % Given the state of the setup, provided by arguments,
            % get the *EXPECTED* offset to apply on the NI AO, to prevent
            % movement on the visual stimulus.
            offset = obj.offsets.get_ni_ao_offset(solenoid_state, gear_mode);
            
            % set the idle voltage on the NI
            obj.ni.ao.idle_offset = repmat(offset, 1, length(obj.ni.ao.chan));
            
            % apply the voltage
            obj.ni.ao.set_to_idle();
        end
        
        
        function multiplexer_listen_to(obj, src)
            % Change the source the multiplexer listens to.
            %
            % :param src: The source that should be listened to ('teensy' or 'ni').
        
            % switch the digital output
            obj.multiplexer.listen_to(src);
        end
        
        
        function cfg = get_config(obj)
            % Get a cell array with config information to save to a text file
            %
            % :return: An Nx2 cell array containing the configuration information of the setup. Each row of the cells array is of the form {<key>, <value>} giving the configuration of a parameter. This is passed to the :attr:`saver` for saving.
        
            [~, git_version]        = system(sprintf('git --git-dir=%s rev-parse HEAD', ...
                                                            obj.saver.git_dir));
            
            cfg = { 'git_version',              git_version;
                    'saving.save_to',           obj.saver.save_to;
                    'saving.prefix',            obj.saver.prefix;
                    'saving.suffix',            obj.saver.suffix;
                    'saving.index',             sprintf('%i', obj.saver.index);
                    'saving.ai_min_voltage',    sprintf('%.1f', obj.saver.ai_min_voltage);
                    'saving.ai_max_voltage',    sprintf('%.1f', obj.saver.ai_max_voltage);
            
                    'nidaq.ai.rate',            sprintf('%.1f', obj.ni.ai.task.Rate);
                    'nidaq.ai.channel_names',   strjoin(obj.ni.ai.channel_names, ',');
                    'nidaq.ai.channel_ids',     strjoin(obj.ni.ai.channel_ids, ',');
                    'nidaq.ai.offset',          strjoin(arrayfun(@(x)(sprintf('%.10f', x)), ...
                                                    obj.data_transform.offset, 'uniformoutput', false), ',')
                    'nidaq.ai.scale',           strjoin(arrayfun(@(x)(sprintf('%.10f', x)), ...
                                                    obj.data_transform.scale, 'uniformoutput', false), ',')
                                                    
                    'nidaq.ao.rate',            sprintf('%.1f', obj.ni.ao.task.Rate);
                    'nidaq.ao.channel_names',   strjoin(obj.ni.ao.channel_names, ',');
                    'nidaq.ao.channel_ids',     strjoin(obj.ni.ao.channel_ids, ',');
                    'nidaq.ao.idle_offset',     sprintf('%.10f', obj.ni.ao.idle_offset);
                    
                    'nidaq.co.channel_names',   strjoin(obj.ni.co.channel_names, ',');
                    'nidaq.co.channel_ids',     strjoin(obj.ni.co.channel_ids, ',');
                    'nidaq.co.init_delay',      sprintf('%i', obj.ni.co.init_delay);
                    'nidaq.co.low_samps',       sprintf('%i', obj.ni.co.low_samps);
                    'nidaq.co.high_samps',      sprintf('%i', obj.ni.co.high_samps);
                    'nidaq.co.clock_src',       obj.ni.co.clock_src;
            
                    'nidaq.do.channel_names',   strjoin(obj.ni.do.channel_names, ',');
                    'nidaq.do.channel_ids',     strjoin(obj.ni.do.channel_ids, ',');
                    'nidaq.do.clock_src',       obj.ni.do.clock_src;
                
                    'nidaq.di.channel_names',   strjoin(obj.ni.di.channel_names, ',');
                    'nidaq.di.channel_ids',     strjoin(obj.ni.di.channel_ids, ',');
                    'timeout_seconds',          sprintf('%.1f', obj.timeout_seconds)};
                
            % add information about delay
            if obj.delayed_velocity.enabled
                cfg{end+1, 1} = 'delay_ms';
                cfg{end, 2} = sprintf('%i', obj.delayed_velocity.delay_ms);
            end
        end
    end
end
