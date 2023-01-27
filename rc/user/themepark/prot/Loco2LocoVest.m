classdef Loco2LocoVest < handle
%   This is not being used
%
% Loco2LocoVest Old class for implementing trial in which there is a
% change in gain between treadmill velocity and stage velocity.
%
%   The trial starts with just the treadmill moving, then at a certain
%   point along the trial, the gain between the treadmill velocity and
%   stage velocity is ramped up to 1, so that the stage follows the
%   treadmill.
%
%   Loco2LocoVest Properties:
%       start_dwell_time        - time in seconds to wait at the beginning of the trial
%       start_pos               - position (in Soloist units) at the start of the trial 
%       back_limit              - backward position beyond which the trial is stopped
%       forward_limit           - forward position beyond which the trial is stopped and reward given

%       switch_pos              - position at which the trigger is sent to the Teensy to change the gain
%       handle_acquisition      - whether we are running this as a single trial (true) or as part of a sequence (false)
%       wait_for_reward         - whether to wait for the reward to be
%                                 given before ending the trial (true) or
%                                 end the trial immediately (false)
%       enable_vis_stim         - whether to send a digital output to the
%                                 visual stimulus computer to enable the
%                                 display (true = enable, false = disable)
%       log_trial               - whether to log the velocity data for this
%                                 trial
%       log_fname               - name of the file in which to log the
%                                 single trial data
%
%       running                 - read only, whether the trial is currently running
%                                 (true = running, false = not running)
%
%   Loco2LocoVest Methods:
%       run                     - run the trial
%       stop                    - stop the trial
%       get_config              - return configuration information for the trial
%
%   See also: Loco2LocoVest, run

    properties
        
        start_dwell_time = 5
        
        start_pos
        
        back_limit
        forward_limit
        
        distance_forward
        distance_switch
        distance_backward
        
        handle_acquisition = true
        wait_for_reward = true
        enable_vis_stim = true
        
        log_trial = false
        log_fname = ''
        
        switch_pos
    end
    
    properties (SetAccess = private)
        
        running = false
        abort = false
    end
    
    properties (Hidden = true)
        
        ctl
    end
    
    
    
    methods
        
        function obj = Loco2LocoVest(ctl, config)
        % Loco2LocoVest
        %
        %   Loco2LocoVest(CTL, CONFIG) creates object handling trials in
        %   which there is a change in gain between treadmill velocity and
        %   stage velocity. CTL is an object of class RC2Controller, giving
        %   access to the setup and CONFIG is the main configuration
        %   structure for the setup.
        %
        %   See also: run
        
            obj.ctl = ctl;
            
            % forward and backward positions as if on the stage
            obj.start_pos = config.stage.start_pos;
            obj.back_limit = config.stage.back_limit;
            obj.forward_limit = config.stage.forward_limit;
            
            obj.switch_pos = (obj.start_pos + obj.forward_limit)/2;
        end
        
        
        
        function val = get.distance_forward(obj)
        %%distance_forward Amount of distance, in mm, to move forward
        %%before stopping the trial
            
            val = obj.start_pos - obj.forward_limit;
        end
        
        
        
        function val = get.distance_switch(obj)
        %%distance_switch Distance to travel before the trigger to the
        %%teensy is sent 
        
            val = obj.start_pos - obj.switch_pos;
        end
        
        
        
        function val = get.distance_backward(obj)
        %%distance_backward Amount of distance, in mm, to move backward
        %%before stopping the trial
        
            val = obj.start_pos - obj.back_limit;
        end
        
        
        
        function final_position = run(obj)
        %%run Runs the trial
        %
        %   MOVED_FORWARD = run() runs the trial. MOVED_FORWARD is either 0
        %   or 1 - 1 indicates the stage moved forward during the trial, 0
        %   indicates that the stage moved backward during the trial or
        %   an error occurred.
        %
        %   Following procedure is performed:
        %
        %       1. Communicate with the Soloist
        %       2. Block the treadmill (if not already blocked)
        %       3. Send signal to switch off the visual stimulus (if not already off)
        %       4. Load the script 'forward_only' to the Teensy (if not already loaded)
        %       5. Save configuration information about the trial
        %       6. Make sure multiplexer is listening to correct source (Teensy)
        %       7. Set TriggerInput to listen to the Soloist input
        %       8. If this is being run as a single trial, play the sound and start NIDAQ
        %       acqusition (do not do this if being run as a sequence, as
        %       the ProtocolSequence object will handle acquisition and
        %       sound)
        %       9. Move the stage to the start position
        %       10. Send signal to switch on the visual stimulus (if
        %       `enable_vis_stim` is true)
        %       11. Start the command to control the stage (see
        %       Soloist.mismatch_ramp_up_until). This waits for a signal
        %       and then ramps up the gain.
        %       12. Start integrating the position on the PC
        %       13. Wait for `start_dwell_time` seconds       
        %       14. Unblock the treadmill
        %       15. If `log_trial` is true, velocity data about this trial
        %       is saved
        %       16. Now wait for the position in Position class to reach
        %       the `switch_pos` position. When the point is reached send a
        %       trigger to the Soloist to increase the gain
        %       17. Wait until a trigger from the Soloist indicating that
        %       the stage has reached either the backward or forward limit
        %       (`back_limit`/`forward_limit`)
        %
        %       After trigger received:
        %           18. Block the treadmill
        %           19. Send signal to switch off visual stimulus
        %           20. If `log_trial` is true, stop logging the trial
        %           21. If position is positive (i.e. moved forward)
        %           provide a reward
        %           22. If this is being run as a single trial, stop NIDAQ
        %           acqusition and sound (do not do this if being run as a sequence, as
        %           the ProtocolSequence object will handle acquisition and
        %           sound)
        %
        %       If error occurs:
        %           a. stop any Soloist programs
        %           b. Block the treadmill
        %           c. Send signal to switch off visual stimulus
        %           d. Stop NIDAQ acquisition
        %           e. Stop logging the trial
        %           f. Stop the sound
        %
        %   Stopping of the trial:
        %
        %       Only at certain points in execution does the program listen for a stop
        %       signal. Therefore, the trial may continue for some time after
        %       the `stop` method is run (e.g. when the stage is moving to its
        %       start position).
        
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
                obj.ctl.trigger_input.listen_to('soloist');
                
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
                
                % go into the mismatch condition
                reward_position = obj.start_pos - (obj.switch_pos - obj.forward_limit);
                obj.ctl.soloist.mismatch_ramp_up_until(obj.back_limit, reward_position)
                
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
                    obj.ctl.start_logging_single_trial(obj.log_fname);
                end
                
                % integrate position of treadmill PC until the bounds are reached
                switch_cm = obj.distance_switch/10;
                backward_cm = obj.distance_backward/10;
                
                while obj.ctl.position.position < switch_cm && obj.ctl.position.position > backward_cm
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        return
                    end
                end
                
                % send trigger to soloist to ramp up
                obj.ctl.start_soloist.start();
                
                % wait for trigger from soloist
                while ~obj.ctl.trigger_input.read()  
                    pause(0.005);
                    if obj.abort
                        obj.running = false;
                        obj.abort = false;
                        %obj.cleanup();
                        return
                    end
                end
                
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
                    final_position = 1;
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
        %%stop Stop the trial
        %
        %   stop()
        %   if the stop method is called, the `abort` property is
        %   temporarily set to true. The main loop will detect this and
        %   abort properly 
        
            obj.abort = true;
        end
        
        
        
        function cfg = get_config(obj)
        %%get_config Return the configuration information for the trial
        %
        %   CONFIG = get_config() returns a Nx2 cell array with
        %   configuration information about the protocol.
        %
        %   See also: RC2Controller.get_config, Saver.save_config
        
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
                'prot.log_fname',           sprintf('%s', obj.log_fname);
                'prot.integrate_using',     '---';
                'prot.wave_fname',          '---';
                'prot.enable_vis_stim',     sprintf('%i', obj.enable_vis_stim);
                'prot.initiate_trial',      '---';
                'prot.initiation_speed',    '---';
                'prot.reward.randomize',    sprintf('%i', obj.ctl.reward.randomize);
                'prot.reward.min_time',     sprintf('%i', obj.ctl.reward.min_time);
                'prot.reward.max_time',     sprintf('%i', obj.ctl.reward.max_time);
                'prot.reward.duration',     sprintf('%i', obj.ctl.reward.duration)};
        end
        
        
        
        function cleanup(obj)
        %%cleanup Execute upon stopping or ending the trial
        %
        %   cleanup() upon finishing the run method the following is
        %   executed:
        %
        %           a. Block the treadmill
        %           b. Send signal to switch off visual stimulus
        %           c. If `handle_acquisition` is true, stop any Soloist
        %           programs, stop NIDAQ acquisition and stop the sound
        %           d. If `log_trial` is true, stop the logging of single
        %           trial data
        
            obj.running = false;
            obj.abort = false;
            
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
