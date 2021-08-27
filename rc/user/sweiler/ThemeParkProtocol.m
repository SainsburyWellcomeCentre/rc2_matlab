classdef ThemeParkProtocol < handle
    
    properties
        
        rc2ctl
        tcp_client_stimulus
        protocol_id
    end
    
    properties
        
        running = false;
        abort = false;
        current_stimulus_type
        
        stimulus_type_list = {}
        is_correct = []
        
        h_listener_reward
    end
    
    properties (SetObservable = true)
        
        current_trial = 0
        
        n_correct_s_plus_trials = 0
        n_incorrect_s_plus_trials = 0
        n_correct_s_minus_trials = 0
        n_incorrect_s_minus_trials = 0
        n_rewards_given = 0;
    end
    
    
    
    methods
        
        function obj = ThemeParkProtocol(rc2ctl, tcp_client_stimulus, protocol_id)
            
            obj.rc2ctl = rc2ctl;
            obj.tcp_client_stimulus = tcp_client_stimulus;
            obj.protocol_id = protocol_id;
            
            obj.h_listener_reward = addlistener(obj.rc2ctl.reward, 'n_rewards_counter', 'PostSet', @obj.n_rewards_given_updated);
        end
        
        
        
        function delete(obj)
            
            delete(obj.h_listener_reward);
        end
        
        
        
        function run(obj)
            
            if ismember(obj.protocol_id, [1:5, 101:104])
                
                % reset variables
                obj.current_trial = 0;
                obj.n_correct_s_plus_trials = 0;
                obj.n_incorrect_s_plus_trials = 0;
                obj.n_correct_s_minus_trials = 0;
                obj.n_incorrect_s_minus_trials = 0;
                
                h = onCleanup(@obj.cleanup);
                
                obj.rc2ctl.reward.reset_n_rewards_counter();
                
                obj.rc2ctl.prepare_acq();
                obj.rc2ctl.start_acq();
                
                obj.running = true;
                
                % keep looping for as long as stimuli are presented
                while true
                    
                    % wait for info from stimulus computer
                    abort_trial = obj.wait_for_trial_start();
                    if abort_trial; return; end
                    
                    % make sure return value is s_plus or s_minus
                    assert(ismember(obj.current_stimulus_type, {'s_plus', 's_minus'}), 'unknown protocol type');
                    
                    % next trial
                    obj.current_trial = obj.current_trial + 1;
                    
                    % print info about the trial
                    fprintf('Trial: %i, stimulus: %s\n', obj.current_trial, obj.current_stimulus_type);
                    
                    fprintf('setting lick detection variables...');
                    % if 's_minus' trial then we suppress the giving of reward
                    if strcmp(obj.current_stimulus_type, 's_minus')
                        obj.rc2ctl.lick_detector.enable_reward = false;
                    else
                        obj.rc2ctl.lick_detector.enable_reward = true;
                    end
                    
                    % reset the lick
                    obj.rc2ctl.lick_detector.start_trial();
                    fprintf('done\n');
                    
                    % send signal back to visual stimulus computer
                    %   assumes that vis stim computer is waiting...
                    fprintf('sending start message to vis stim computer\n');
                    obj.tcp_client_stimulus.writeline('start_trial');
                    
                    % wait for trial to end
                    abort_trial = obj.wait_for_trial_end();
                    if abort_trial; return; end
                    
                    % store stimulus type
                    fprintf('trial finished, updating response variables...');
                    obj.stimulus_type_list{obj.current_trial} = obj.current_stimulus_type;
                    
                    % if the protocol is S+, then lick is correct response
                    if strcmp(obj.current_stimulus_type, 's_plus')
                        
                        if obj.rc2ctl.lick_detector.lick_detected
                            % correct S+ trial
                            obj.is_correct(obj.current_trial) = true;
                            obj.n_correct_s_plus_trials = obj.n_correct_s_plus_trials + 1;
                        else
                            % incorrect S+ trial
                            obj.is_correct(obj.current_trial) = false;
                            obj.n_incorrect_s_plus_trials = obj.n_incorrect_s_plus_trials + 1;
                        end
                        
                    elseif strcmp(obj.current_stimulus_type, 's_minus')
                        
                        if obj.rc2ctl.lick_detector.lick_detected
                            % incorrect S- trial
                            obj.is_correct(obj.current_trial) = false;
                            obj.n_incorrect_s_minus_trials = obj.n_incorrect_s_minus_trials + 1;
                        else
                            % correct S- trial
                            obj.is_correct(obj.current_trial) = true;
                            obj.n_correct_s_minus_trials = obj.n_correct_s_minus_trials + 1;
                        end
                    end
                    fprintf('done\n');
                    
                end
            end
            % let cleanup handle the stopping
        end
        
        
        
        function stop(obj)
            
            obj.abort = true;
        end
        
        
        
        function cleanup(obj)
            
            fprintf('trial stopped, cleaning up\n');
            obj.running = false;
            obj.tcp_client_stimulus.writeline('rc2_stopping');
            delete(obj.tcp_client_stimulus);
            
            % log the info
            fname = [obj.rc2ctl.saver.save_root_name(), '_themepark.mat'];
            fname = fullfile(obj.rc2ctl.saver.save_fulldir, fname);
            bin_fname = obj.rc2ctl.saver.logging_fname();
            
            obj.rc2ctl.stop_acq();
            
            protocol_number = obj.protocol_id;
            n_trials = length(obj.stimulus_type_list);
            stimulus_type = obj.stimulus_type_list;
            response = obj.is_correct;
            
            save(fname, 'protocol_number', 'n_trials', 'stimulus_type', 'response');
            
            try    
                analyze_and_plot_licking_data(bin_fname);
            catch
            end
            
            delete(obj.h_listener_reward);
        end
        
        
        
        function n_rewards_given_updated(obj, ~, ~)
            
            obj.n_rewards_given = obj.rc2ctl.reward.n_rewards_counter;
        end
        
        
        
        function abort_trial = wait_for_trial_start(obj)
            
            if obj.tcp_client_stimulus.NumBytesAvailable == 0
                fprintf('waiting for trial type\n');
            end
            
            abort_trial = false;
            while obj.tcp_client_stimulus.NumBytesAvailable == 0
                pause(0.001);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    abort_trial = true;
                    return
                end
            end
            
            % get protocol type 's_plus' or 's_minus'
            fprintf('reading trial type... ');
            obj.current_stimulus_type = obj.tcp_client_stimulus.readline();
            fprintf('%s\n', obj.current_stimulus_type);
        end
        
        
        
        function abort_trial = wait_for_trial_end(obj)
            
            if obj.tcp_client_stimulus.NumBytesAvailable == 0
                fprintf('waiting for end of trial message\n');
            end
            
            abort_trial = false;
            while obj.tcp_client_stimulus.NumBytesAvailable == 0
                pause(0.001);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    abort_trial = true;
                    return
                end
            end
            
            fprintf('reading end of trial message');
            msg = obj.tcp_client_stimulus.readline();
            fprintf('%s\n', msg);
            assert(strcmp(msg, 'trial_end'));
        end
    end
end
