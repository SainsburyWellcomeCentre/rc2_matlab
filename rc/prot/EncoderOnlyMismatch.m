classdef EncoderOnlyMismatch < handle
    
    properties
        
        start_dwell_time = 5
        
        stage_pos
        back_limit
        forward_limit
        
        switch_pos
        mismatch_duration
        gain_direction = 'down'
        
        direction
        
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        log_trial = false
        log_fname = ''
        
        integrate_using = 'pc'  % 'teensy' or 'pc'
    end
    
    properties (SetAccess = private)
        
        running = false
        abort = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    properties (Dependent = true)
        
        distance_forward
        distance_backward
        distance_switch
    end
    
    
    methods
        
        function obj = EncoderOnlyMismatch(ctl, config)
            
            obj.ctl = ctl;
            
            % forward and backward positions as if on the stage
            obj.stage_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            
            obj.direction = 'forward_only_variable_gain';
        end
        
        
        function val = get.distance_forward(obj)
            
            val = obj.stage_pos - obj.forward_limit;
        end
        
        
        function val = get.distance_backward(obj)
            
            val = obj.stage_pos - obj.back_limit;
        end
        
        
        function val = get.distance_switch(obj)
            
            val = obj.stage_pos - obj.switch_pos;
        end
        
        function final_position = run(obj)
            
            try
               
                % times simulating features of other protocols
                %   calibration time + connection to soloist (~6s)
                %   moveback of stage from one end to other (~7s)
                simulate_calibration_s = 6;
                simulate_moveback = 7;
                
                % report the end position
                final_position = 0;
                
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
                
                % make sure vis stim is off
                obj.ctl.vis_stim.off();
                
                % prevent output of the teensy until just before the trial
                obj.ctl.disable_teensy.on();
                
                % load correct direction on teensy
                obj.ctl.teensy.load(obj.direction);
                
                
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % listen to correct source
                obj.ctl.multiplexer_listen_to('teensy');
                
                % start acquiring data if the protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % move to position along stage where the trial will take
                % place
                proc = obj.ctl.soloist.move_to(obj.stage_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                % we want to reset the position
                obj.ctl.reset_pc_position();
                
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
                
                % wait a bit of time before starting the trial
                tic;
                while toc < obj.start_dwell_time
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % enable the teensy again
                obj.ctl.disable_teensy.off();
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging velocity if required.
                if obj.log_trial
                    obj.ctl.start_logging_single_trial(obj.log_fname);
                end
                
                
                % integrate position on PC until the bounds are reached
                forward_cm = obj.distance_forward/10;
                switch_cm = obj.distance_switch/10;
                
                obj.ctl.position.start();
                
                while obj.ctl.position.position < switch_cm
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                if strcmp(obj.gain_direction, 'up')
                    obj.ctl.teensy_gain.gain_up_on();
                elseif strcmp(obj.gain_direction, 'down')
                    obj.ctl.teensy_gain.gain_down_on();
                end
                
                % wait for mismatch to finish
                tic;
                while toc < obj.mismatch_duration
                    
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                    
                    % except if the final position is reached
                    if obj.ctl.position.position > forward_cm
                        break
                    end
                end
                
                
                if strcmp(obj.gain_direction, 'up')
                    obj.ctl.teensy_gain.gain_up_off();
                elseif strcmp(obj.gain_direction, 'down')
                    obj.ctl.teensy_gain.gain_down_off();
                end
                
                
                % wait for end of trial
                while obj.ctl.position.position < forward_cm
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                obj.ctl.position.stop();
                
                % add 500ms to end of trial (= gain change time on soloist)
                tic;
                while toc < 0.5
                    pause(0.005);
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % switch vis stim off
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.off();
                end
                
                % stop logging single trial
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % make sure the stage has moved foward before giving reward
                if obj.ctl.get_position() > 0
                    final_position = 1;
                    % start reward, block until finished if necessary
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
                end
                
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
                
                % stop acquiring data if protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
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
                'prot.start_pos',           '---';
                'prot.stage_pos',           sprintf('%.3f', obj.stage_pos);
                'prot.back_limit',          sprintf('%.3f', obj.back_limit);
                'prot.forward_limit',       sprintf('%.3f', obj.forward_limit);
                'prot.direction',           obj.direction;
                'prot.start_dwell_time',    sprintf('%.3f', obj.start_dwell_time);
                'prot.handle_acquisition',  sprintf('%i', obj.handle_acquisition);
                'prot.wait_for_reward',     sprintf('%i', obj.wait_for_reward);
                'prot.log_trial',           sprintf('%i', obj.log_trial);
                'prot.log_fname',           sprintf('%s', obj.log_fname);
                'prot.integrate_using',     obj.integrate_using;
                'prot.wave_fname',          '---';
                'prot.enable_vis_stim',     sprintf('%i', obj.enable_vis_stim);
                'prot.initiate_trial',      '---';
                'prot.initiation_speed',    '---';
                'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration);
                'prot.switch_pos',          sprintf('%.3f', obj.switch_pos);
                'prot.mismatch_duration',   sprintf('%.3f', obj.mismatch_duration);
                'prot.gain_direction',      obj.gain_direction};
                
        end
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.abort = false;
            
            fprintf('running cleanup in encoder\n')
            
            obj.ctl.block_treadmill();
            obj.ctl.vis_stim.off();
            obj.ctl.position.stop();
            
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