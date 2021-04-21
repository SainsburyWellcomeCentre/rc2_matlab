classdef Controller < handle
    
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
        %%obj = CONTROLLER(config)
        %   Main class for interfacing with the rollercoaster setup.
        %       config - configuration structure containing necessary
        %           parameters for setup - usually this is created with
        %           config_default, but of course you can define your own
        %           config structure
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
            delete(obj.plotting);
            
            % make sure that all devices are stopped properly
            obj.soloist.abort()
            obj.sound.stop()
            obj.stop_acq()
            obj.ni.close()
        end
        
        
        function start_preview(obj)
            
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
            
            % if we are not acquiring preview don't do anything.
            if ~obj.acquiring_preview; return; end
            % if we are acquiring and saving don't do anything
            if obj.acquiring; return; end
            
            % set acquring flag to false and stop NI-DAQ
            obj.acquiring_preview = false;
            obj.ni.stop_acq(false);  % false indicates that clock is not on.
        end
        
        
        function h_preview_callback(obj, ~, evt)
            
            % store the current data
            obj.data = evt.Data;
            
            % transform data
            obj.tdata = obj.data_transform.transform(obj.data);
            
            % pass transformed data to plotter
            obj.plotting.ni_callback(obj.tdata);
        end
        
        
        function prepare_acq(obj)
            if obj.acquiring || obj.acquiring_preview
                error('already acquiring data')
                return %#ok<UNRCH>
            end
            
            obj.saver.setup_logging();
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            obj.plotting.reset_vals();
        end
        
        
        function start_acq(obj)
            
            % if already acquiring don't do anything
            if obj.acquiring || obj.acquiring_preview; return; end
            
            % start the NI-DAQ device and set acquiring flag to true
            obj.ni.start_acq()
            obj.acquiring = true;
        end
        
        
        function h_callback(obj, ~, evt)
            
            % store the data so others can use it
            obj.data = evt.Data;
            
            % log raw voltage
            obj.saver.log(evt.Data);
            
            % transform data
            obj.tdata = obj.data_transform.transform(evt.Data);
            
            % pass transformed data to callbacks
            obj.plotting.ni_callback(obj.tdata);
            obj.position.integrate(obj.tdata(:, 1));
        end
        
        
        function stop_acq(obj)
            if ~obj.acquiring; return; end
            if obj.acquiring_preview; return; end
            obj.acquiring = false;
            obj.ni.stop_acq();
            obj.saver.stop_logging();
        end
        
        
        function play_sound(obj)
            obj.sound.play()
        end
        
        
        function stop_sound(obj)
            obj.sound.stop()
        end
        
        
        function give_reward(obj)
%             obj.reward.give_reward();
            obj.reward.start_reward(0)
        end
        
        
        function block_treadmill(obj, gear_mode)
            
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.block()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('up', gear_mode);
            end
        end
        
        
        function unblock_treadmill(obj, gear_mode)
            
            VariableDefault('gear_mode', 'off');
            
            obj.treadmill.unblock()
            
            % change the offset on the NI
            %   unless it is already running a waveform
            if ~obj.ni.ao.task.IsRunning
                obj.set_ni_ao_idle('down', gear_mode);
            end
        end
        
        
        function pump_on(obj)
            obj.pump.on()
        end
        
        
        function pump_off(obj)
            obj.pump.off()
        end
        
        
        function move_to(obj, pos, speed, leave_enabled)
            
            VariableDefault('speed', obj.soloist.default_speed);
            VariableDefault('leave_enabled', false);
            
            obj.soloist.move_to(pos, speed, leave_enabled);
        end
        
        
        function home_soloist(obj)
            obj.soloist.home();
        end
        
        
        function ramp_velocity(obj)
            
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

            if obj.delayed_velocity.enabled
                waveform = obj.delayed_velocity.create_waveform(waveform);
            end
            
            % write a waveform (in V)
            obj.ni.ao_write(waveform);
        end
        
        
        function play_velocity_waveform(obj)
            obj.ni.ao_start();
        end
        
        
        function set_save_save_to(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_save_to(str)
        end
        
        
        function set_save_prefix(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_prefix(str)
        end
        
        
        function set_save_suffix(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_suffix(str)
        end
        
        
        function set_save_index(obj, val)
            if obj.acquiring; return; end
            obj.saver.set_index(val)
        end
        
        
        function set_save_enable(obj, val)
            if obj.acquiring; return; end
            obj.saver.set_enable(val)
        end
        
        
        %%% TRIAL LOGGING
        function fid = start_logging_single_trial(obj, fname)
            
            % open file for saving
            fid = obj.saver.start_logging_single_trial(fname);
            
            % throw warning if file couldn't be opened
            if fid == -1
                warning('Not logging single trial. Specified file name: %s', fname);
            end
        end
        
        
        function save_single_trial_config(obj, cfg)
            obj.saver.append_config(cfg);
        end
        
        
        function stop_logging_single_trial(obj)
            obj.saver.stop_logging_single_trial()
        end
        
        
        function reset_pc_position(obj)
            %obj.position.reset();
        end
        
        
        function reset_teensy_position(obj)
            obj.zero_teensy.zero();
        end
        
        
        function pos = get_position(obj)
            pos = obj.position.position;
        end
        
        
        function set_ni_ao_idle(obj, solenoid_state, gear_mode)
            
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
            
            % switch the digital output
            obj.multiplexer.listen_to(src);
        end
        
        
        
        function cfg = get_config(obj)
            
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