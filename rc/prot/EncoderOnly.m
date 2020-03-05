classdef EncoderOnly < handle
    
    properties
        
        start_dwell_time = 5
        
        stage_pos
        back_limit
        forward_limit
        direction
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        log_trial = false
        
        integrate_using = 'teensy'  % 'teensy' or 'pc'
    end
    
    properties (SetAccess = private)
        log_trial_fname
        running = false
        abort = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    properties (Dependent = true)
        
        distance_forward
        distance_backward
    end
    
    
    methods
        
        function obj = EncoderOnly(ctl, config)
            obj.ctl = ctl;
            
            % forward and backward positions as if on the stage
            obj.stage_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            
            obj.direction = 'forward_only';
        end
        
        
        function val = get.distance_forward(obj)
            
            val = obj.stage_pos - obj.forward_limit;
        end
        
        
        function val = get.distance_backward(obj)
            
            val = obj.stage_pos - obj.back_limit;
        end
        
        
        function final_position = run(obj)
            
            try
               
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
                
                % load correct direction on teensy
                obj.ctl.teensy.load(obj.direction);
                
                
                cfg = obj.get_config();
                obj.ctl.save_single_trial_config(cfg);
                
                % start listening to the correct trigger input
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.trigger_input.listen_to('teensy');
                end
                
                % start acquiring data if the protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.start_acq();
                end
                
                % move to position along stage where the trial will take
                % place
                proc = obj.ctl.soloist.move_to(obj.stage_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(0.5);
                
                
                % if we are using the teensy to determine position reset
                % the position onboard teensy
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.reset_teensy_position();
                end
                
                 % we want to reset the position anyway
                obj.ctl.reset_pc_position();
                
                % switch vis stim on
                if obj.enable_vis_stim
                    obj.ctl.vis_stim.on();
                else
                    obj.ctl.vis_stim.off();
                end
                
                
                % start integrating the position
                obj.ctl.position.start();
                
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
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging velocity if required.
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                if strcmp(obj.integrate_using, 'teensy')
                    
                    % wait for the trigger from the teensy
                    while ~obj.ctl.trigger_input.read()
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    
                else
                    
                    % integrate position on PC until the bounds are reached
                    forward_cm = obj.distance_forward/10;
                    backward_cm = obj.distance_backward/10;
                    
                    obj.ctl.position.start();
                    while obj.ctl.position.position < forward_cm && obj.ctl.position.position > backward_cm
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    obj.ctl.position.stop();
                end
                
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
                
                % stop integrating position
                obj.ctl.position.stop();
                
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
        
        
        function prepare_as_sequence(~, ~, ~)
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
                'prot.integrate_using',     obj.integrate_using;
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