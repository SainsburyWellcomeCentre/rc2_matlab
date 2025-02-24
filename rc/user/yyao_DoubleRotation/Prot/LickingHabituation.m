classdef LickingHabituation < handle
    
    properties
        ctl
        config
        sequence = {}
        running = false;
        abort = false;
        current_sequence
        
%         stimulus_type_list = {}
%         is_correct = []
        h_listener_reward
%         h_listener_ao
        
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
        function obj = LickingHabituation(ctl, config, view)
            obj.ctl = ctl; 
            obj.config = config;
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

%             obj.h_listener_ao = addlistener(obj.ctl.ni.ao.task, 'IsRunning', 'PostSet', @(src, evnt)obj.visual_stimuli(src, evnt, enable_vis_stim));     

            obj.ctl.reward.reset_n_rewards_counter();   
            
%             obj.ctl.play_sound(); 
            obj.ctl.ensemble_online(true);
            all_axes = obj.ctl.ensemble.all_axes;   % [0,1]

            obj.ctl.set_target_axes(all_axes);
            obj.ctl.home_ensemble(false);        % home both motors
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
                
                
                % setup current trial lick detector
                obj.ctl.lick_detector.enable_reward = obj.sequence{i}.trial.enable_reward;
                obj.ctl.lick_detector.start_trial();    % reset the lick detector
                
                % store stimulus type
%                 obj.stimulus_type_list{obj.current_trial} = obj.sequence{i}.trial.stimulus_type;   % save trial type of current trial to sequence
                
                fprintf('Trial %i: preperation done\n',i);
                
                %% Start trial
                
                % send signal back to visual stimulus computer
                % assumes that vis stim computer is waiting...
                fprintf('sending starting message to vis stim computer\n');
                obj.ctl.communication.tcp_client_stimulus.writeline('start_trial');   % send 'start_trial' to remote host
                fprintf('start_trial\n');
                
                % refresh lick detector every 7.5 sec
                for i= 1:8
                    obj.ctl.vis_stim.on();
                    obj.ctl.waveform_peak_trigger();
                    if obj.ctl.lick_detector.lick_detected == true
                        obj.ctl.lick_detector.start_trial();    % reset the lick detector
                    end
                    pause(7.5);
                end
                
                % wait for vis_stim to end
                abort_trial = obj.wait_for_trial_end();   % receive 'trial_end' from remote host to continue
                if abort_trial; return; end
                
                %%% trial protocol end %%%
                
                %% inter trial interval
                
                fprintf('trial done\n');
            end     % trial end



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
            lick_threshold = obj.ctl.lick_detector.lick_threshold;
            
%             obj.ctl.vis_stim.off();
            obj.ctl.stop_acq();         
%             obj.ctl.abort_ao_task();
%             obj.ctl.stop_sound();   
            
            protocol_name = obj.ctl.saver.index;
            n_rewards_given = obj.n_rewards_given;
            
            save(fname, 'protocol_name', 'n_rewards_given', 'lick_threshold');  % save variables to .mat file
            
            try    
                AnalyzeAndPlotLickingData_DoubleRotation(bin_fname);   
            catch
            end
            
            delete(obj.h_listener_reward);
%             delete(obj.h_listener_ao);
            
        end
    end
end