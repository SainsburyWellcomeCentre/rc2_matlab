classdef Shelter < handle
    properties
        start_pos % Position (in Soloist units) at the start of the trial.
        direction % Direction of travel (name of Teensy script, e.g. 'forward_only' or 'forward_and_backward').
        handle_acquisition = true % Boolean specifying whether we are running this as a single trial (true) or as part of a :class:`rc.prot.ProtocolSequence` (false).
        wait_for_reward = true % Boolean specifying whether to wait for the reward to be given before ending the trial (true) or end the trial immediately (false).
        back_limit % Backward position beyond which the trial is stopped.
        forward_limit % Forward position beyond which the trial is stopped and reward given.
        
        log_trial = false % Boolean specifying whether to log the velocity data for this trial.
        log_fname = '' % Name of the file in which to log the single trial data.
        
        solenoid_correction = 1.55 % How much to correct for voltage differences when solenoid is up or down (mV).
    end
    
    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
    end
    
    properties (Hidden = true)
        ctl % :class:`rc.main.Controller` object controller.
    end
    
    methods
        function obj = Shelter(ctl, config)
            % Constructor for a :class:`rc.prot.Shelter` protocol.
            %
            % :param ctl: :class:`rc.main.Controller` object for interfacing with the stage.
            % :param config: The main configuration file.
        
            obj.ctl = ctl;
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            obj.direction = 'forward_and_backward';
        end
        
        function final_position = run(obj)
            % Runs the trial
            %
            % :return: Flag (0/1) indicating trial outcome. 1 indicated the stage moved forward during the trial. 0 Indicates the stage moved backward during the trial or an error occurred.
            
            try
                % set default return
                final_position = 0;

                % set running
                obj.running = true;

                % setup code to handle premature stopping
                h = onCleanup(@obj.cleanup);

                % startup initial communication
                proc = obj.ctl.soloist.communicate();
                proc.wait_for(0.5);
                
                % prepare to acquire data
                disp("prepare acquisition");
                if obj.handle_acquisition
                    obj.ctl.prepare_acq();
                end
                
                % make sure the treadmill is blocke
                obj.ctl.block_treadmill();
                
                % make sure vis stim is off
                obj.ctl.vis_stim.off();
                
                % load teensy
                obj.ctl.teensy.load(obj.direction);
                
                % get and save config - TODO
                
                % listen to correct source
                obj.ctl.multiplexer_listen_to('teensy');
                
                % start PC listening to the correct trigger input
                obj.ctl.trigger_input.listen_to('soloist');
                
                % start the move to operation and wait for the process to
                % terminate.
                proc = obj.ctl.soloist.move_to(obj.start_pos, obj.ctl.soloist.default_speed, true);
                proc.wait_for(2);
                
                % MOVEMENT STUFF
                disp("listen position");
                obj.ctl.soloist.listen_position(obj.back_limit, obj.forward_limit, false);
                
                % release block on the treadmill
                obj.ctl.unblock_treadmill();            
                
                % wait for stage to reach the position
                while ~obj.ctl.trigger_input.read()  
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        %obj.cleanup();
                        return
                    end
                end
                
                disp("end listen");
                
                % block the treadmill
                obj.ctl.block_treadmill()
                
                obj.ctl.disable_teensy.off();
                
%                 % stop logging the single trial.
%                 if obj.log_trial
%                     obj.ctl.stop_logging_single_trial();
%                 end
                
                % Reset PSO
                obj.ctl.soloist.reset_pso();
                
                % if handling the acquisition stop 
                if obj.handle_acquisition
                    obj.ctl.stop_acq();
                    obj.ctl.stop_sound();
                end

                % end of the protocol, no longer running
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
                if obj.log_trial
                    obj.ctl.stop_logging_single_trial();
                end
                obj.ctl.stop_sound();
                
                rethrow(ME)
            end
        end
        
        function stop(obj)
            % Stop the trial.
            % If the stop method is called, the :attr:`abort` property is
            % temporarily set to true. The main loop will detect this and
            % abort properly.
        
            obj.abort = true;
        end
        
        function cleanup(obj)
            % Execute upon stopping or ending the trial.
            % a. Block the treadmill
            % b. Send signal to switchy off visual stimulus
            % c. If :attr:`handle_acquisition` it true, stop any Soloist programs, stop NIDAQ acquisition and stop the sound
            % d. If :attr:`log_trial` is true, stop the logging of single trial data.
        
            obj.running = false;
            obj.abort = false;
            
            fprintf('running cleanup in coupled\n')
            
            obj.ctl.block_treadmill()
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

