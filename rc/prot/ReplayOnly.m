classdef ReplayOnly < handle
    
    properties
        
        start_dwell_time = 5;
        
        start_pos
        
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        initiate_trial = false;
        initiation_speed = 5;
        
        wave_fname
        waveform
        
        direction = 'forward_only'
    end
    
    properties (SetAccess = private)
        
        running = false
        abort = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = ReplayOnly(ctl, config, fname)
        % Protocol for replaying a waveform out of the multiplexer through
        % NI.
            
            VariableDefault('fname', []);
            
            % main controller object
            obj.ctl = ctl;
            
            % position 
            obj.start_pos = config.stage.start_pos;
            
            % filename containing the data to replay
            obj.wave_fname = fname;
        end
        
        
        function load_wave(obj)
        % Load a waveform from a binary file.
            
            if isempty(obj.wave_fname); return; end
            
            w = double(read_bin(obj.wave_fname, 1)); % file must be single channel
            
            % store the waveform
            waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;  %#ok<*PROP> %TODO:  config... but StageOnlys shouldn't have to worry about it.
            
            obj.waveform = obj.ctl.offsets.transform_ai_ao_data(waveform, 'up', 'off');
        end
        
        
        function final_position = run(obj)
            
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
            obj.abort = true;
        end
        
        
        function cfg = get_config(obj)
            
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