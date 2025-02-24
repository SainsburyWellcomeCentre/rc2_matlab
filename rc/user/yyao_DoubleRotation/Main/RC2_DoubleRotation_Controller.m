classdef RC2_DoubleRotation_Controller < handle
    
    properties
        
        communication
        tic
        ni
        ensemble
        pump
        reward
        plotting
        saver
        sound
        data_transform
        offsets
        lick_detector

        vis_stim
%         trial_start
        waveform_peak

        data
        tdata
    end
    
    
    properties (SetObservable = true, SetAccess = private, Hidden = true)
        
        acquiring = false
        acquiring_preview = false;
        
        version = '1.0'
    end
    
    
    
    methods
        
        function obj = RC2_DoubleRotation_Controller(config)
        %%obj = RC2_DoubleRotation_Controller(config)
        %   Main class for interfacing with the rollercoaster setup.            
        %       config - configuration structure containing necessary           
        %           parameters for setup - usually this is created with         
        %           config_default, but of course you can define your own
        %           config structure
        %   For information on each property see the related class.             
            
            obj.communication = TCPIPcommunication_DoubleRotation (config);
            obj.tic = tic;  
            obj.ni = NI(config);   
            obj.ensemble = Ensemble_DoubleRotation(config);   % control stage rotation
            obj.pump = Pump(obj.ni, config);   
            obj.reward = Reward(obj.pump, config);  
            obj.plotting = Plotting_DoubleRotation(config);   
            obj.sound = Sound_DoubleRotation(config);         
            obj.saver = Saver_DoubleRotation(obj, config);    
            obj.data_transform = DataTransform(config);
            obj.offsets = Offsets(obj, config);
            obj.lick_detector = LickDetect_DoubleRotation(obj, config);
            
            % Triggers
            obj.vis_stim = VisStim_DoubleRotation(obj.ni, config);
%             obj.trial_start = TrialStart_DoubleRotation(obj.ni, config);
            obj.waveform_peak = WaveformPeak_DoubleRotation(obj.ni, config);
            
            obj.lick_detector.power_on();
        end
        
        
        function delete(obj)
            delete(obj.plotting);
            
            % make sure that all devices are stopped properly
            obj.ensemble.abort()
            obj.sound.stop()
            obj.stop_acq()
            obj.ni.close()
        end
        
        

        %% NIDAQ
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
        
        
        
        function val = ni_ai_rate(obj)
            val = obj.ni.ai_rate();  % 10000
        end

        function abort_ao_task(obj)
            obj.ni.ao.stop();
%             obj.ni.ao.close();
        end

        %% Stage (Ensemble)
        function move_to(obj, pos, speed, leave_enabled)
            
            VariableDefault('pos', obj.ensemble.default_position);
            VariableDefault('speed', obj.ensemble.default_speed);
            VariableDefault('leave_enabled', false);
            
            obj.ensemble.move_to(pos, speed, leave_enabled);
        end
        
        
        function home_ensemble(obj, leave_enabled)
%             obj.ensemble.force_home();
            obj.ensemble.home(leave_enabled);
        end
        
        function set_target_axes(obj,axes)
            obj.ensemble.set_targetaxes(axes);
        end
        
%         function ramp_velocity(obj)
%             
%             % create a 1s ramp to 10mm/s
%             rate = obj.ni.ao_rate;
%             ramp = obj.soloist.v_per_cm_per_s * (0:rate-1) / rate;
%             
%             % use the first idle_offset value. we are assuming the ONLY use
%             % case for other analog channels is for a delayed copy of the
%             % velocity waveform...
%             waveform = obj.ni.ao_idle_offset(1) + ramp';
%             obj.load_velocity_waveform(waveform);
%             pause(0.1);
%             obj.play_velocity_waveform();
%         end
        
        
        function load_velocity_waveform(obj, waveform)

%             if obj.delayed_velocity.enabled
%                 waveform = obj.delayed_velocity.create_waveform(waveform);
%             end
            
            % write a waveform (in V)
            obj.ni.ao_write(waveform);
        end
        
        
        function play_velocity_waveform(obj)
            obj.ni.ao_start();
            obj.ensemble.set_homed(obj.ensemble.target_axes, false);
        end

        function ensemble_online(obj, logicallabel)
            obj.ensemble.set_online(obj.ensemble.all_axes, logicallabel);
        end


        %% Protocol
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
            obj.lick_detector.reset();                        
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
%             obj.position.integrate(obj.tdata(:, 1));
            obj.lick_detector.loop();    

        end
        
        
        function stop_acq(obj)
            if ~obj.acquiring; return; end
            if obj.acquiring_preview; return; end
            obj.acquiring = false;
            obj.ni.stop_acq();             
            obj.saver.stop_logging();
        end
        
        %% Pump
        function give_reward(obj)
%             obj.reward.give_reward();
            obj.reward.start_reward(0)
        end
        
        function pump_on(obj)
            obj.pump.on()
        end
        
        
        function pump_off(obj)
            obj.pump.off()
        end

        %% Sound
        function play_sound(obj)
            obj.sound.play()
        end
        
        
        function stop_sound(obj)
            obj.sound.stop()
        end
        
        
        %% AI Preview
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
        
        
        

        %% Save
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
        

        %% Trigger
        function visual_stimuli(obj, enable_vis_stim)
            if obj.ni.ao.task.IsRunning && enable_vis_stim
                obj.vis_stim.on();      % sending TTL to miniDAQ to start visual stimuli 
            else
                obj.vis_stim.off();
            end
        end
        
        function trial_start_trigger(obj)
            obj.trial_start.start();
        end

        function waveform_peak_trigger(obj)
            obj.waveform_peak.start();
        end

        %% Saving Config
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
                    'nidaq.ao.idle_offset',     strjoin(arrayfun(@(x)(sprintf('%.10f', x)), ...
                                                    obj.ni.ao.idle_offset, 'uniformoutput', false), ',')
                    
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
                %{
                if obj.delayed_velocity.enabled
                    cfg{end+1, 1} = 'delay_ms';
                    cfg{end, 2} = sprintf('%i', obj.delayed_velocity.delay_ms);
                end
                %}    
        end
    end
end