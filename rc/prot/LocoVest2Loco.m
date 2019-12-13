classdef LocoVest2Loco < handle
    
    properties
        
        start_dwell_time = 5 % must be > 3
        
        start_pos
        back_limit
        forward_limit
        distance_forward
        distance_backward
        
        handle_acquisition = true
        wait_for_reward = true
        
        log_trial = false
        
        time_to_halt = 0.2; %
        switch_pos
    end
    
    
    properties (SetAccess = private)
        
        log_trial_fname
        running = false
        abort = false
    end
    
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = LocoVest2Loco(ctl, config)
            
            obj.ctl = ctl;
            
            % forward and backward positions as if on the stage
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            
            obj.switch_pos = (obj.start_pos + obj.forward_limit)/2;
        end
        
        
        function val = get.distance_forward(obj)
            val = obj.start_pos - obj.forward_limit;
        end
        
        
        function val = get.distance_backward(obj)
            val = obj.start_pos - obj.back_limit;
        end
        
        
        function final_position = run(obj)
            
            try
                
                % report the end position
                final_position = 0;
                
                % we are running the protocol
                obj.running = true;
                
                % prepare code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % startup initial communication
                proc = obj.ctl.soloist.communicate();
                proc.wait_for(0.5);
                
                % prepare to acquire data
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                % make sure the treadmill is blocked at the start
                obj.ctl.block_treadmill();
                
                % make sure vis stim is off
                obj.ctl.vis_stim.off();
                
                % load teensy
                obj.ctl.teensy.load('forward_only');
                
                % get and save config
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to the teensy at first
                obj.ctl.multiplexer.listen_to('teensy');
                
                % start listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('teensy');
                
                % if this protocol is handling itself start the sound and
                % prepare the acquisition
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % start the "move to" operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                % reset position on the PC
                obj.ctl.reset_pc_position();
                
                % reset position on the teensy
                obj.ctl.reset_teensy_position();
                
                % switch vis stim on
                obj.ctl.vis_stim.on();
                
                % the soloist will connect, setup some parameters and then
                % wait for the solenoid signal to go low
                % we need to give it some time to setup (~2s, but we want
                % to wait at the start position anyway...
                obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit);
                
                % start integrating position on PC
                obj.ctl.position.start();
                
                % wait
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
                % this will simultaneously start the soloist
                obj.ctl.unblock_treadmill()
                
                % start logging the single trial if necessary
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                % convert mm to cm
                back_pos_cm = (obj.start_pos - obj.back_limit)/10;
                switch_pos_cm = (obj.start_pos - obj.switch_pos)/10;
                
                % wait for stage to reach the desired position
                while obj.ctl.position.position < switch_pos_cm && obj.ctl.position.position > back_pos_cm
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                
                % get the current velocity (voltage)
                % TODO dont assume channel
                voltage = mean(obj.ctl.data(:, 1));
                
                % output the voltage on analog output
                obj.ctl.ni.ao.task.outputSingleScan(voltage+obj.ctl.ni.ao.ai_ao_error);
                
                % listen to the ni to stop
                obj.ctl.multiplexer.listen_to('ni');
                
                % create waveform
                waveform = linspace(voltage, obj.ctl.ni.ao.idle_offset, round(obj.time_to_halt * obj.ctl.ni.ao.task.Rate))';
                
                % load the waveform
                obj.ctl.load_velocity_waveform(waveform);
                
                % play stop waveform
                obj.ctl.play_velocity_waveform()
                
                % integrate position of treadmill PC until the bounds are reached
                forward_cm = obj.distance_forward/10;
                backward_cm = obj.distance_backward/10;
                
                while obj.ctl.position.position < forward_cm && obj.ctl.position.position > backward_cm
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                %while ~obj.ctl.trigger_input.read()
                %    pause(0.005);
                %    if obj.abort
                %        obj.running = false;
                %        obj.abort = false;
                %        return
                %    end
                %end
                
                % reset ni output
                obj.ctl.set_ni_ao_idle();
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % switch vis stim off
                obj.ctl.vis_stim.off();
                
                % abort the soloist
                obj.ctl.soloist.stop()
                
                % stop integrating position
                obj.ctl.position.stop();
                
                % stop logging the single trial.
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % wait for reward to complete then stop acquisition
                % make sure the stage has moved foward
                if obj.ctl.get_position() > 0
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
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
                obj.ctl.set_ni_ao_idle();
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                obj.ctl.stop_sound();
                rethrow(ME)
            end
        end
        
        
        function stop(obj)
            % if the stop method is called, set the abort property
            % temporarily to false
            % the main loop will detect this and abort properly
            obj.abort = true;
        end
        
        
        function prepare_as_sequence(~, ~, ~)
        end
        
        
        function cfg = get_config(obj)
            
            cfg = {
                'prot.time_started',        datestr(now, 'yyyymmdd_HH_MM_SS')
                'prot.type',                class(obj);
                'prot.start_pos',           sprintf('%.3f', obj.start_pos);
                'prot.stage_pos',           '---';
                'prot.switch_pos',          sprintf('%.3f', obj.switch_pos);
                'prot.back_limit',          sprintf('%.3f', obj.back_limit);
                'prot.forward_limit',       sprintf('%.3f', obj.forward_limit);
                'prot.direction',           '---';
                'prot.start_dwell_time',    sprintf('%.3f', obj.start_dwell_time);
                'prot.handle_acquisition',  sprintf('%i', obj.handle_acquisition);
                'prot.wait_for_reward',     sprintf('%i', obj.wait_for_reward);
                'prot.log_trial',           sprintf('%i', obj.log_trial);
                'prot.integrate_using',     '---';
                'prot.wave_fname',          '---';
                'prot.follow_previous_protocol', '---';
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
            obj.ctl.set_ni_ao_idle();
            
            if obj.handle_acquisition
                obj.ctl.soloist.stop();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
            end
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
            
        end
    end
end