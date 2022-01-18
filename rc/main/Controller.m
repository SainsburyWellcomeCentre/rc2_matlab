classdef Controller < handle
% RC2Controller Main class for interfacing with the rollercoaster setup
%
%   RC2Controller Properties:
%         ni                - object of class NI
%         teensy            - object of class Teensy
%         soloist           - object of class Soloist
%         pump              - object of class Pump
%         reward            - object of class Reward
%         treadmill         - object of class Treadmill
%         multiplexer       - object of class Multiplexer
%         plotting          - object of class Plotting
%         saver             - object of class Saver
%         sound             - object of class Sound
%         position          - object of class Position
%         zero_teensy       - object of class ZeroTeensy
%         disable_teensy    - object of class DisableTeensy
%         trigger_input     - object of class TriggerInput
%         data_transform    - object of class DataTransform
%         vis_stim          - object of class VisStim
%         start_soloist     - object of class StartSoloist
%         offsets           - object of class Offsets
%         teensy_gain       - object of class TeensyGain
%         delayed_velocity  - object of class DelayedVelocity
%         
%         data              - data matrix with latest voltage data
%         tdata             - data matrix with transformed data
%
%         acquiring         - true or false, whether we are currently acquiring data
%         acquiring_preview - true or false, whether we are currently acquiring preview data
%
%   RC2Controller Methods:
%       delete              - destructor
%       start_preview       - start previewing and displaying analog input data
%       stop_preview        - stop previewing and displaying analog input data
%       h_preview_callback  - callback function for previewing data
%       prepare_acq         - prepare for main acquisiton of data
%       start_acq           - start acquiring and displaying data
%       h_callback          - callback function for acquiring data
%       stop_acq            - stop acquiring and displaying data
%       play_sound          - play the sound
%       stop_sound          - stop the sound
%       give_reward         - give a reward
%       block_treadmill     - block the treadmill
%       unblock_treadmill   - unblock the treadmill
%       pump_on             - turn the pump on
%       pump_off            - turn the pump off
%       move_to             - move the linear stage to a position
%       home_soloist        - home the soloist
%       ramp_velocity       - ramp the velocity on the soloist
%       load_velocity_waveform - load a velocity waveform to the NIDAQ
%       play_velocity_waveform - play the velocity waveform loaded on the NIDAQ
%       set_save_save_to    - set the save to directory
%       set_save_prefix     - set the save file prefix
%       set_save_suffix     - set the save file suffix
%       set_save_index      - set the save file index
%       set_save_enable     - enable the saving of files
%       start_logging_single_trial - save the velocity for a single trial
%       save_single_trial_config - save config for a single trial
%       stop_logging_single_trial - stop logging a single trial
%       reset_pc_position   - set the internal PC position to zero
%       reset_teensy_position - reset the internal Teensy position to zero
%       get_position        - get the current position value
%       set_ni_ao_idle      - set the NI AO to its "idle" voltage
%       multiplexer_listen_to  - change the source the mux listens to
%       get_config          - return a cell array with config information to save to a text file

    properties
        
        ni
        teensy
        soloist
        pump
        reward
        treadmill
        multiplexer
        plotting
        saver
        sound
        position
        zero_teensy
        disable_teensy
        trigger_input
        data_transform
        vis_stim
        start_soloist
        offsets
        teensy_gain
        delayed_velocity
        
        data
        tdata
    end
    
    
    properties (SetObservable = true, SetAccess = private, Hidden = true)
        
        acquiring = false
        acquiring_preview = false;
    end
    
    
    
    methods
        
        function obj = Controller(config)
        % Controller
        %
        %   Controller(CONFIG)
        %   Main class for interfacing with the rollercoaster setup.
        %       CONFIG - configuration structure containing necessary
        %           parameters for setup.
        %
        %   For information on each property see the related class.
        
            obj.ni = NI(config);
            obj.teensy = Teensy(config);
            obj.soloist = Soloist(config);
            obj.pump = Pump(obj.ni, config);
            obj.reward = Reward(obj.pump, config);
            obj.treadmill = Treadmill(obj.ni, config);
            obj.multiplexer = Multiplexer(obj.ni, config);
            obj.plotting = Plotting(config);
            obj.sound = Sound();
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
            
        end
        
        
        function delete(obj)
        %%delete Destructor
        
            delete(obj.plotting);
            
            % make sure that all devices are stopped properly
            obj.soloist.abort()
            obj.sound.stop()
            obj.stop_acq()
            obj.ni.close()
        end
        
        
        
        function start_preview(obj)
        %%start_preview Start previewing and displaying analog input data
        %
        %   start_preview() starts preview of analog input data
        
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
        %%stop_preview Stop previewing and displaying analog input data
        %
        %   stop_preview() stops the preview of analog input data if it is
        %   previewing
        
            % if we are not acquiring preview don't do anything.
            if ~obj.acquiring_preview; return; end
            % if we are acquiring and saving don't do anything
            if obj.acquiring; return; end
            
            % set acquring flag to false and stop NI-DAQ
            obj.acquiring_preview = false;
            obj.ni.stop_acq(false);  % false indicates that clock is not on.
        end
        
        
        
        function h_preview_callback(obj, ~, evt)
        %%h_preview_callback Callback function for previewing data
        %
        %   h_preview_callback() callback function during preview
        
            % store the current data
            obj.data = evt.Data;
            
            % transform data
            obj.tdata = obj.data_transform.transform(obj.data);
            
            % pass transformed data to plotter
            obj.plotting.ni_callback(obj.tdata);
        end
        
        
        
        function prepare_acq(obj)
        %%prepare_acq Prepare for main acquisiton of data
        %
        %   prepare_acq() prepares for main acquisition of data including
        %   setup of files in which to save data and config information,
        %   preparation of the nidaq for acquisition and resetting of
        %   display
        %
        %   TODO: this should be called by start_acq()
        %
        %   See also: Saver.setup_logging, NI.prepare_acq, Plotting
        
            if obj.acquiring || obj.acquiring_preview
                error('already acquiring data')
                return %#ok<UNRCH>
            end
            
            obj.saver.setup_logging();
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            obj.plotting.reset_vals();
        end
        
        
        
        function start_acq(obj)
        %%start_acq Start acquiring and displaying data
        %
        %   start_acq() start main acquisition and saving of data
        %
        %   See also: NI
        
            % if already acquiring don't do anything
            if obj.acquiring || obj.acquiring_preview; return; end
            
            % start the NI-DAQ device and set acquiring flag to true
            obj.ni.start_acq()
            obj.acquiring = true;
        end
        
        
        
        function h_callback(obj, ~, evt)
        %%h_callback Callback function for acquiring data
        %
        %   h_callback() callback for main acquisition. This saves the
        %   data, transforms the data into sensible units, plots the data
        %   and integrates a velocity trace to estimate the position of the
        %   stage.
        %
        %   See also: Saver, DataTransform, 
        %
        %   TODO: currently passes the first column of the data matrix
        %   to the Position class to estimate position. This will break if
        %   the first column is not a velocity trace
        
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
        %%stop_acq Stop acquiring and displaying data
        %
        %   stop_acq() stops the main acquisiton
        %
        %   See also: start_acq
        
            if ~obj.acquiring; return; end
            if obj.acquiring_preview; return; end
            
            obj.acquiring = false;
            obj.ni.stop_acq();
            obj.saver.stop_logging();
        end
        
        
        
        function play_sound(obj)
        %%play_sound Play the sound
        %
        %   play_sound()
        %
        %   See also: Sound
        
            obj.sound.play()
        end
        
        
        
        function stop_sound(obj)
        %%stop_sound Stop the sound
        %
        %   stop_sound()
        %
        %   See also: Sound
        
            obj.sound.stop()
        end
        
        
        
        function give_reward(obj)
        %%give_reward Give a reward
        %
        %   give_reward()
        %
        %   See also: Reward
        
%             obj.reward.give_reward();
            obj.reward.start_reward(0)
        end
        
        
        
        function block_treadmill(obj, gear_mode)
        %%block_treadmill Block the treadmill
        %
        %   block_treadmill()
        %
        %   See also: Treadmill
        
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.block()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('up', gear_mode);
            end
        end
        
        
        
        function unblock_treadmill(obj, gear_mode)
        %%unblock_treadmill Unblock the treadmill
        %
        %   unblock_treadmill()
        %
        %   See also: Treadmill
        
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.unblock()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('down', gear_mode);
            end
        end
        
        
        
        function pump_on(obj)
        %%pump_on Turn the pump on
        %
        %   pump_on()
        %
        %   See also: Pump
        
            obj.pump.on()
        end
        
        
        
        function pump_off(obj)
        %%pump_off Turn the pump off
        %
        %   pump_off()
        %
        %   See also: Pump
        
            obj.pump.off()
        end
        
        
        
        function move_to(obj, pos, speed, leave_enabled)
        %%move_to Move the linear stage to a position
        %
        %   move_to(POSITION, SPEED, LEAVE_ENABLED) moves the linear stage to
        %   the position POSITION (units are in Soloist controller units,
        %   which for us has always been mm), at speed SPEED (also units in
        %   controller units, for us this has been mm/s). LEAVE_ENABLED is
        %   a logical, true or false, and determines whether to leave the
        %   stage enabled after the move has been made (true) or disable
        %   the stage after the move (false). See Soloist class for more
        %   information.
        %
        %   See also: Soloist.move_to
        
            VariableDefault('speed', obj.soloist.default_speed);
            VariableDefault('leave_enabled', false);
            
            obj.soloist.move_to(pos, speed, leave_enabled);
        end
        
        
        
        function home_soloist(obj)
        %%home_soloist Home the soloist
        %
        %   home_soloist() 
        %
        %   See also: Soloist.home
        
            obj.soloist.home();
        end
        
        
        
        function ramp_velocity(obj)
        %%ramp_velocity Ramp the velocity on the soloist
        %
        %   ramp_velocity() creates a 1s linear ramped waveform from idle_offset(1)
        %   to (idle_offset(1) + soloist.v_per_cm_per_s) and loads and
        %   plays this on the analog output. (See config for description of
        %   `idle_offset` and `v_per_cm_per_s`).
        %
        %   The final voltage will remain on the analog output at the end
        %   of the ramp, so the user should be careful to reset the analog
        %   output if this is used.
        
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
        %%load_velocity_waveform Load a velocity waveform to the NIDAQ
        %
        %   load_velocity_waveform(WAVEFORM) writes a waveform to analog
        %   output ready to be output. 
        %
        %   If there is a delayed copy to be output on the second analog
        %   output, the waveform will be duplicated with the
        %   DelayedVelocity class. Thus, in this case the waveform provided
        %   here should be single dimensional. 
        %
        %   See also: play_velocity_waveform, NI.ao_write, DelayedVelocity
        
            if obj.delayed_velocity.enabled
                waveform = obj.delayed_velocity.create_waveform(waveform);
            end
            
            % write a waveform (in V)
            obj.ni.ao_write(waveform);
        end
        
        
        
        function play_velocity_waveform(obj)
        %%play_velocity_waveform Play the velocity waveform loaded on the NIDAQ
        %
        %   play_velocity_waveform() plays any waveforms which have been
        %   written to the analog outputs.
        %
        %   See also: load_velocity_waveform, NI
        
            obj.ni.ao_start();
        end
        
        
        
        function set_save_save_to(obj, str)
        %%set_save_save_to Set the save to directory
        %
        %   set_save_save_to(STRING) sets the main directory in which to
        %   save data. .bin files are saved in the form:
        %
        %       <save_to_dir>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_prefix, set_save_suffix, set_save_index, Saver
        
            if obj.acquiring; return; end
            obj.saver.set_save_to(str)
        end
        
        
        
        function set_save_prefix(obj, str)
        %%set_save_prefix Set the save file prefix
        %
        %   set_save_prefix(STRING)  sets the prefix of the files to save
        %   to. .bin files are saved in the form:
        %
        %       <save_to_dir>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_save_to, set_save_suffix, set_save_index, Saver
        
            if obj.acquiring; return; end
            obj.saver.set_prefix(str)
        end
        
        
        
        function set_save_suffix(obj, str)
        %%set_save_suffix Set the save file suffix
        %
        %   set_save_suffix(STRING) sets the suffix of the files to save
        %   to. .bin files are saved in the form:
        %
        %       <save_to_dir>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_save_to, set_save_prefix, set_save_index, Saver
        
            if obj.acquiring; return; end
            obj.saver.set_suffix(str)
        end
        
        
        
        function set_save_index(obj, val)
        %%set_save_index Set the save file index
        %
        %   set_save_index(VALUE) sets the index of the files to save
        %   to. .bin files are saved in the form:
        %
        %       <save_to_dir>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_save_to, set_save_prefix, set_save_suffix, Saver
        
            if obj.acquiring; return; end
            obj.saver.set_index(val)
        end
        
        
        function set_save_enable(obj, val)
        %%set_save_enable Enable the saving of files
        %
        %   set_save_enable(VALUE) sets whether to save data on main
        %   acquisition of not. VALUE is a boolean, true to save, false
        %   don't save.
        %
        %   See also: Saver
        
            if obj.acquiring; return; end
            obj.saver.set_enable(val)
        end
        
        
        
        function fid = start_logging_single_trial(obj, fname)
        %%start_logging_single_trial Save the velocity for a single trial
        %
        %   FID = start_logging_single_trial(FILENAME) sets up files for
        %   simultaneous logging of single trials, or short segments of the
        %   main acquisition. FILENAME is the full path to the file in
        %   which to log the data.
        %
        %   See also: stop_logging_single_trial, Saver.start_logging_single_trial
        
            % open file for saving
            fid = obj.saver.start_logging_single_trial(fname);
            
            % throw warning if file couldn't be opened
            if fid == -1
                warning('Not logging single trial. Specified file name: %s', fname);
            end
        end
        
        
        
        function save_single_trial_config(obj, cfg)
        %%save_single_trial_config Save config for a single trial
        %
        %   save_single_trial_config(CONFIG_STRUCT) appends configuration
        %   information to the *main* configuration file for the
        %   acquisition. CONFIG_STRUCT is 
        %
        %   See also: Saver, Saver.append_config
        
            obj.saver.append_config(cfg);
        end
        
        
        
        function stop_logging_single_trial(obj)
        %%stop_logging_single_trial Stop logging a single trial
        %
        %   stop_logging_single_trial() closes the files to do with logging
        %   single trial/short segments of the main acquisition.
        %
        %   See also: start_logging_single_trial,
        %   Saver.stop_logging_single_trial
        
            obj.saver.stop_logging_single_trial()
        end
        
        
        
        function reset_pc_position(obj)
        %%reset_pc_position 
            %obj.position.reset();
        end
        
        
        
        function reset_teensy_position(obj)
        %%reset_teensy_position Reset the internal Teensy position to zero
        %
        %   reset_teensy_position() sends a trigger to the Teensy to reset
        %   the internal position variable to zero.
        %
        %   See also: ZeroTeensy
        
            obj.zero_teensy.zero();
        end
        
        
        
        function pos = get_position(obj)
        %%get_position Get the current position value
        %
        %   get_position() returns the current position value from the
        %   Position class.
        %
        %   See also: Position
        
            pos = obj.position.position;
        end
        
        
        
        function set_ni_ao_idle(obj, solenoid_state, gear_mode)
        %%set_ni_ao_idle Set the NI AO to its "idle" voltage
        %
        %   set_ni_ao_idle(SOLENOID_STATE, GEAR_MODE) given the state of
        %   the setup apply an `idle_offset` on the analog output.
        %
        %   SOLENOID_STATE gives the state of the solenoid
        %   ('up' or 'down') and GEAR_MODE whether the Soloist is in gear
        %   mode or not ('on' or 'off').
        %
        %   See also: Offsets
        
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
        %%multiplexer_listen_to Change the source the mux listens to
        %
        %   multiplexer_listen_to(SOURCE) changes the output of the
        %   multiplexer from one input to the other. SOURCE is a string
        %   which currently is either 'teensy' or 'ni'.
        %
        %   See also: Multiplexer
        
            % switch the digital output
            obj.multiplexer.listen_to(src);
        end
        
        
        
        function cfg = get_config(obj)
        %%get_config Return a cell array with config information to save to a text file
        %
        %   CONFIG = get_config() returns a Nx2 cell array in CONFIG
        %   containing the configuration information of the setup. Each row
        %   of the cell array is of the form {<key>, <value>} giving the
        %   configuration of a parameter <key> in <value>. This is passed
        %   to the Saver class for saving.
        %
        %   See also: Saver, Saver.save_config
        
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
                    'nidaq.di.channel_ids',     strjoin(obj.ni.di.channel_ids, ',')};
                
            % add information about delay
            if obj.delayed_velocity.enabled
                cfg{end+1, 1} = 'delay_ms';
                cfg{end, 2} = sprintf('%i', obj.delayed_velocity.delay_ms);
            end
        end
    end
end
