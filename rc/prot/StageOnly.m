classdef StageOnly < handle
    
    properties
        
        start_dwell_time = 5;
        
        ctl
        start_pos
        back_limit
        forward_limit
        direction
        wave_fname
        waveform
        
        handle_acquisition = true
        wait_for_reward = true
        follow_previous_protocol = false
        log_trial = false
    end
    
    properties (SetAccess = private)
        log_trial_fname
        running = false
        abort = false
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
            obj.load_wave();
        end
        
        
        function load_wave(obj)
            if isempty(obj.wave_fname); return; end
            w = double(read_bin(obj.wave_fname, 1)); % file must be single channel
            obj.waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;  %TODO:  config... but StageOnlys shouldn't have to worry about it.
        end
        
        
        function set_fname(obj, fname)
            obj.wave_fname = fname;
            obj.load_wave();
        end
        
        
        function final_position = run(obj)
            
            try
                
                % always assume it has finished in positive direction
                final_position = 1;
                
                if isempty(obj.waveform)
                    fprintf('NO WAVEFORM LOADED, SKIPPING\n')
                    return
                end
                
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % make sure the treadmill is blocked
                obj.ctl.block_treadmill();
                
                % load teensy and listen to correct source
                obj.ctl.multiplexer.listen_to('ni');
                
                % start listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('soloist');
                
                % load the velocity waveform to NIDAQ
                obj.ctl.load_velocity_waveform(obj.waveform);
                
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.prepare_acq();
                    obj.ctl.start_acq();
                end
                
                % start the move to operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit);
                
                % wait five seconds
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
                
                % start logging the single trial
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                % start playing the waveform
                obj.ctl.play_velocity_waveform()
                
                % look out for the waveform finishing, but the trigger not
                % being received
                premature_end = false;
                
                % wait for process to terminate.
                % TODO:  setup an event to unblock treadmill on digital
                % input.
                while ~obj.ctl.trigger_input.read()
                    
                    if ~obj.ctl.ni.ao.task.IsRunning
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
%                 if premature_end
%                     obj.ctl.ramp_velocity();
%                 end
                
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
                
                
                % block treadmill
                obj.ctl.block_treadmill()
                
                % stop logging the single trial.
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % wait for reward to complete then stop acquisition
                obj.ctl.reward.start_reward(obj.wait_for_reward)
                
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
                % set voltage waveform to the idle value
                obj.ctl.set_ni_ao_idle();
                
                % the protocol is no longer running
                obj.running = false;
                
            catch ME
                
                % if an error has occurred, perform the following whether
                % or not the singple protocol is handling the acquisition
                obj.running = false;
                obj.ctl.soloist.abort();
                obj.ctl.block_treadmill();
                obj.ctl.stop_acq();
                obj.ctl.stop_logging_single_trial();
                obj.ctl.stop_sound();
                rethrow(ME)
            end
        end
        
        
        function stop(obj)
            obj.abort = true;
        end
        
        
        function prepare_as_sequence(obj, fname)
            if ~isempty(fname)
                obj.set_fname(fname);
            end
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
                'prot.integrate_using',     '---';
                'prot.wave_fname',          obj.wave_fname;
                'prot.follow_previous_protocol', sprintf('%i', obj.follow_previous_protocol);
                'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration)};
        end
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.abort = false;
            
            obj.ctl.block_treadmill()
            
            if obj.handle_acquisition
                obj.ctl.soloist.abort();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
                %TODO: stop waveform running
            end
        end
    end
end