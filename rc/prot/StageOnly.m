classdef StageOnly < handle
    
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
            VariableDefault('fname', []);
            
            obj.ctl = ctl;
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_only';
            obj.wave_fname = fname;
        end
        
        
        function load_wave(obj)
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