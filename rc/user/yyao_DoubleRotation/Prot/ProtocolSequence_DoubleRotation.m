classdef ProtocolSequence_DoubleRotation < handle
    
    properties
        ctl
        sequence = {}
        running = false;
        abort = false;
        current_sequence
        
        stimulus_type_list = {}
        is_correct = []
        h_listener_reward
        h_listener_ao
        
    end
    
    properties (SetObservable = true)
        current_trial = 0;
        n_correct_s_plus_trials = 0
        n_incorrect_s_plus_trials = 0
        n_correct_s_minus_trials = 0
        n_incorrect_s_minus_trials = 0
        n_rewards_given = 0;
    end
    
    properties (Hidden = true)
        gui_view
    end
    
    methods
        function obj = ProtocolSequence_DoubleRotation(ctl,view)
            obj.ctl = ctl;  
            obj.h_listener_reward = addlistener(obj.ctl.reward, 'n_rewards_counter', 'PostSet', @obj.n_rewards_given_updated); 
            
            
            obj.gui_view = view;
        end
        
        function add(obj, protocol)
            obj.sequence{end+1} = protocol;
        end
        
        function delete(obj)
            delete(obj.h_listener_reward);
        end
        
        function run(obj,enable_vis_stim)
            
            obj.prepare();
            
            h = onCleanup(@obj.cleanup);  

            obj.h_listener_ao = addlistener(obj.ctl.ni.ao.task, 'IsRunning', 'PostSet', @(src, evnt)obj.visual_stimuli(src, evnt, enable_vis_stim));     

            obj.ctl.reward.reset_n_rewards_counter();   
            
            obj.ctl.play_sound(); 
            obj.ctl.ensemble_online(true);
            all_axes = obj.ctl.ensemble.all_axes;   % [0,1]

%             handle = EnsembleConnect;               % tuning with Clive
%             cmd = 'WAIT MODE INPOS';
%             EnsembleCommandExecute(handle, cmd);

            obj.ctl.set_target_axes(all_axes);
            obj.ctl.home_ensemble(true);        % home both motors
            pause(1);
            obj.ctl.prepare_acq();   
            obj.ctl.start_acq();     
            obj.running = true;
            enable_stage = false;
            
            if enable_vis_stim      % if enable VisStim
                fprintf('prepare to start\n');
                    while obj.ctl.communication.tcp_client.NumBytesAvailable == 0
                    end
                return_message = obj.ctl.communication.tcp_client.readline();
           
                if ~strcmp(return_message, 'ready')     % receive 'ready' from remote host to continue
                    fprintf('preperation failed\n')
                    obj.stop(); % abort and reset
                end
            end

            for i = 1 : length(obj.sequence)    % trial start
                
                %% preperation
                obj.current_sequence = obj.sequence{i};
                obj.current_trial = i;
                
                % setup current trial stage rotation
                if obj.sequence{i}.stage.enable_motion
                    enable_stage = true;
                    target_axes = obj.ctl.ensemble.all_axes;  % [0,1]
                    if ~obj.sequence{i}.stage.central.enable
                        target_axes(1) = NaN;
                    end
                    if ~obj.sequence{i}.stage.outer.enable
                        target_axes(2) = NaN;
                    end

                    % load waveform
                    waveform = obj.sequence{i}.waveform;
                    obj.ctl.load_velocity_waveform(waveform);       % load the velocity waveform to NIDAQ
                    obj.ctl.set_target_axes(all_axes);
                    obj.ctl.ensemble.reset_pso();                   % Reset PSO of all axes
                    obj.ctl.set_target_axes(target_axes);
                    ensembleHandle = obj.ctl.ensemble.listen();     % Set the ensemble target_axes to listen
                    fprintf('stage rotation preparation done. \n');
                end
                
                % setup current trial visual stimuli
                if obj.sequence{i}.vis.enable_vis_stim          % if enable VisStim
                    fprintf('start_vis_stim_preparation\n'); 

                    % send current trial visual stimuli information to remote host
                    cmd = sprintf('%i', obj.sequence{i}.vis.vis_stim_lable);   
                    fprintf('sending current trial to visual stimulus computer\n'); 
                    obj.ctl.communication.tcp_client_stimulus.writeline(cmd);  
                    
                    fprintf('waiting for visual stimulus computer\n');
                    while obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                    end
                    return_message = obj.ctl.communication.tcp_client_stimulus.readline(); 
    
                    if ~strcmp(return_message, 'received')          % confirm that remote host has received the message
                        fprintf('trial type message failed\n')
                        obj.stop();
                    end
                end
                
                % setup current trial lick detector
                obj.ctl.lick_detector.enable_reward = obj.sequence{i}.trial.enable_reward;
                obj.ctl.lick_detector.start_trial();    % reset the lick detector
                
                % store stimulus type
%                 fprintf('trial finished, updating response variables...');
                obj.stimulus_type_list{obj.current_trial} = obj.sequence{i}.trial.stimulus_type;   % save trial type of current trial to sequence
                
                fprintf('Trial %i: preperation done\n',i);
                
                %% Start trial
                
                % send signal back to visual stimulus computer
                % assumes that vis stim computer is waiting...
                fprintf('sending starting message to vis stim computer\n');
                obj.ctl.communication.tcp_client_stimulus.writeline('start_trial');   % send 'start_trial' to remote host
                
                %%% trial protocol start %%%
%                 obj.ctl.trial_start_trigger();  % at the beginning of the trial, send TTL pulse to trigger the start of lick detection. lick_detect trigger from DO 'port0/line2' to AI5
                t_trigger = timer;  % at the beginning of the trial, build a timer to trigger lick_detection
                t_trigger.TimerFcn = @(~,~)obj.ctl.waveform_peak_trigger();
                t_trigger.StartDelay = obj.ctl.lick_detector.delay;       
                
                if obj.sequence{i}.stage.enable_motion      % if enable stage rotation
                    % moving the stages
                    obj.ctl.play_velocity_waveform();   % Start playing the waveform on the NIDAQ, meanwhile NIDAQ AO is detected by visstim_trigger and start to send TTL to switch on VisStim on the VisStim PC
                    start(t_trigger);                   % start timer. when time is out send TTL pulse to trigger the start of lick detection. lick_detect trigger from DO 'port0/line2' to AI5
                    while obj.ctl.ni.ao.task.IsRunning  % check to see AO is still running
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end                                 % when NIDAQ AO stops, stages stop moving and VisStim TTL is back to low to switch off VisStim on the VisStim PC

%                     pause(0.5);     % tuning with Clive

                    obj.ctl.set_target_axes(target_axes);
%                     obj.ctl.ensemble.stop_listen(ensembleHandle,true);      % Stop Ensemble listen
                    if ~obj.sequence{i}.vis.enable_vis_stim     % if enable stage but disable VisStim (Rotation in Darkness task)
%                         fprintf('sending trial ending message to vis stim computer\n');
                        obj.ctl.communication.tcp_client_stimulus.writeline('end_trial');   % send 'end_trial' to remote host at trial end
                    end
                elseif obj.sequence{i}.vis.enable_vis_stim  % if disable stage but enable VisStim (Visual Only task) 
                    start(t_trigger);
                    % wait for vis_stim to end
                    abort_trial = obj.wait_for_trial_end();   % receive 'trial_end' from remote host to continue
                    if abort_trial; return; end
                end
                %%% trial protocol end %%%
                
                %% inter trial interval
                % if the protocol is S+, then lick is correct response
                if strcmp(obj.sequence{i}.trial.stimulus_type, 's_plusL')||strcmp(obj.sequence{i}.trial.stimulus_type, 's_plusR')

                    if obj.ctl.lick_detector.lick_detected   
                        % correct S+ trial
                        obj.is_correct(obj.current_trial) = true;  
                        obj.n_correct_s_plus_trials = obj.n_correct_s_plus_trials + 1;
                    else
                        % incorrect S+ trial
                        obj.is_correct(obj.current_trial) = false;
                        obj.n_incorrect_s_plus_trials = obj.n_incorrect_s_plus_trials + 1;
                    end

                elseif strcmp(obj.sequence{i}.trial.stimulus_type, 's_minusL')||strcmp(obj.sequence{i}.trial.stimulus_type, 's_minusR')

                    if obj.ctl.lick_detector.lick_detected
                        % incorrect S- trial
                        obj.is_correct(obj.current_trial) = false;
                        obj.n_incorrect_s_minus_trials = obj.n_incorrect_s_minus_trials + 1;
                    else
                        % correct S- trial
                        obj.is_correct(obj.current_trial) = true;
                        obj.n_correct_s_minus_trials = obj.n_correct_s_minus_trials + 1;
                    end
                end
                
                pause(2);     % wait for 2 seconds before reset stages
                if obj.sequence{i}.stage.enable_motion      
                    obj.ctl.ensemble.stop_listen(ensembleHandle,true);      % Stop Ensemble listen
                end
                % reset stages
                obj.ctl.set_target_axes(all_axes);
                obj.ctl.home_ensemble(true);        % reset both stages to Homed position

                pause(2);     % wait for 2 seconds after reset stages
                
                fprintf('trial done\n');
            end     % trial end

            if enable_stage
                fprintf('sending ending message to vis stim computer\n');
                obj.ctl.communication.tcp_client_stimulus.writeline('end_experiment');   % send 'end_experiment' to finish and quit experiment
            end

            fprintf('Protocol finished\n');
            % let cleanup handle the stopping
        end
        
        function visual_stimuli(obj, ~, ~, enable_vis_stim)
            obj.ctl.visual_stimuli(enable_vis_stim);
        end
        
        function prepare(obj)
            
            obj.current_trial = 0;
            obj.n_correct_s_plus_trials = 0;
            obj.n_incorrect_s_plus_trials = 0;
            obj.n_correct_s_minus_trials = 0;
            obj.n_incorrect_s_minus_trials = 0;
            obj.n_rewards_given = 0;
            
        end
        
        
        function stop(obj)
            
            if isempty(obj.current_sequence)
                return
            end
            obj.abort = true;
            obj.cleanup();
%             obj.current_sequence.stop();
            %delete(obj.current_sequence);
            obj.current_sequence = [];
        end
        
        
        function abort_trial = wait_for_trial_end(obj)
            
            if obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                fprintf('waiting for end of trial message\n');
            end
            
            abort_trial = false;
            while obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                pause(0.001);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    abort_trial = true;
                    return
                end
            end
            
            fprintf('reading end of trial message');
            msg = obj.ctl.communication.tcp_client_stimulus.readline();   
            fprintf('%s\n', msg);
            assert(strcmp(msg, 'trial_end'));   
        end

        function n_rewards_given_updated(obj, ~, ~)
            obj.n_rewards_given = obj.ctl.reward.n_rewards_counter;   
        end

        
        function cleanup(obj)
            
            fprintf('running cleanup in protseq\n')
            obj.running = false;
            obj.ctl.ensemble.stop();
            obj.ctl.ensemble_online(false);
            obj.ctl.communication.tcp_client_stimulus.writeline('rc2_stopping');
            obj.ctl.communication.delete();
            obj.gui_view.handles.StartExperimentButton.Value = 0;
            obj.gui_view.handles.StartExperimentButton.Text = 'Start Experiment';

            % log the info
            fname = [obj.ctl.saver.save_root_name(), '_themepark.mat'];   
            fname = fullfile(obj.ctl.saver.save_fulldir, fname);   
            bin_fname = obj.ctl.saver.logging_fname();  
            
%             obj.ctl.vis_stim.off();
            obj.ctl.stop_acq();         
            obj.ctl.abort_ao_task();
            obj.ctl.stop_sound();   
            
            protocol_name = obj.ctl.saver.index;
            n_trials = length(obj.stimulus_type_list);
            stimulus_type = obj.stimulus_type_list;
            response = obj.is_correct;
            
            save(fname, 'protocol_name', 'n_trials', 'stimulus_type', 'response');  % save variables to .mat file
            
            try    
                AnalyzeAndPlotLickingData_DoubleRotation(bin_fname);   % 
%                 AnalyzeAndPlotRotationData_DoubleRotation(bin_fname);
            catch
            end
            
            delete(obj.h_listener_reward);
            delete(obj.h_listener_ao);
            
        end
    end
end