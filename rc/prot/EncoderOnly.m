classdef EncoderOnly < handle
    
    properties
        
        stage_pos
        back_limit
        forward_limit
        direction
        handle_acquisition = true
        wait_for_reward = true
        
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
        
        
        function run(obj)
            
            try
                
                obj.running = true;
                
                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);
                
                % load correct direction on teensy
                obj.ctl.teensy.load(obj.direction);
                
                % start listening to the correct trigger input
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.trigger_input.listen_to('teensy');
                end
                
                % start acquiring data if the protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.play_sound();
                    obj.ctl.prepare_acq();
                    obj.ctl.start_acq();
                end
                
                % move to position along stage where the trial will take
                % place
                proc = obj.ctl.soloist.move_to(obj.stage_pos, obj.ctl.soloist.default_speed, true);
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
                
                % wait a bit of time before starting the trial
                tic;
                while toc < 5
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % we want to reset the position anyway
                obj.ctl.reset_pc_position();
                
                % start integrating the position
                obj.ctl.position.stop();
                
                % if we are using the teensy to determine position reset
                % the position onboard teensy
                if strcmp(obj.integrate_using, 'teensy')
                    obj.ctl.reset_teensy_position();
                end
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill()
                
                % start logging velocity if required.
                if obj.log_trial
                    obj.log_trial_fname = obj.ctl.start_logging_single_trial();
                end
                
                % wait for trigger from teensy
                if strcmp(obj.integrate_using, 'teensy')
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
                    %obj.ctl.integrate_until(obj.distance_backward, obj.distance_forward);
                end
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                % stop logging single trial
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                
                % make sure the stage has moved foward before giving reward
                if obj.ctl.get_position() > 0
                    % start reward, block until finished if necessary
                    obj.ctl.reward.start_reward(obj.wait_for_reward)
                end
                
                % stop integrating the position
                obj.ctl.position.stop();
                
                % stop acquiring data if protocol is handling that
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end
                
                obj.running = false;
                
            catch ME
                
                % if an error has occurred, perform the following whether
                % or not the singple protocol is handling the acquisition
                obj.running = false;
                obj.ctl.soloist.abort();
                obj.ctl.block_treadmill();
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
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.abort = false;
            
            obj.ctl.block_treadmill()
            
            if obj.handle_acquisition
                obj.ctl.soloist.abort();
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
            end
            
            if obj.log_trial
                obj.ctl.stop_logging_single_trial();
            end
            
        end
    end
end