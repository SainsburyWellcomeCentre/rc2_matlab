classdef StageOnly < handle
    
    properties
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
    end
    
    properties (SetAccess = private)
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
        
        
        function run(obj)
            
            try
                
                if isempty(obj.waveform)
                    fprintf('NO WAVEFORM LOADED, SKIPPING\n')
                    return
                end
                
                %cfg = obj.get_config();
                %obj.ctl.save_single_trial_config(cfg);
                
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
                
                % wait until process controlling movement is finished
%                 while proc.proc.isAlive()
%                     pause(0.005);
%                     if obj.abort
%                         obj.running = false;
%                         obj.abort = false;
%                         return
%                     end
%                 end
                
                obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit, 'ni');
                
                % wait five seconds
                tic;
                while toc < 5
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
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