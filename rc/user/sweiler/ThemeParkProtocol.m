classdef ThemeParkProtocol < handle
    
    properties
        
        rc2ctl
        tcp_client
        protocol_id
    end
    
    properties
        
        running = false;
        abort = false;
        current_stimulus_type
        
        stimulus_type_list = {}
        is_correct = []
        lick_detected = -1
    end
    
    properties (SetObservable = true)
        
        current_trial = 0
        
        n_correct_s_plus_trials = 0
        n_incorrect_s_plus_trials = 0
        n_correct_s_minus_trials = 0
        n_incorrect_s_minus_trials = 0
    end
    
    
    
    methods
        
        function obj = ThemeParkProtocol(rc2ctl, tcp_client, protocol_id)
            
            obj.rc2ctl = rc2ctl;
            obj.tcp_client = tcp_client;
            obj.protocol_id = protocol_id;
            
            addlistener(obj.rc2ctl.lick_detector, 'lick_occurred_in_window', ...
                'PostSet', @obj.lick_notification);
        end
        
        
        
        function run(obj)
            
            if ismember(obj.protocol_id, 2:5)
                
                % reset
                obj.current_trial = 0;
                
                obj.n_correct_s_plus_trials = 0;
                obj.n_incorrect_s_plus_trials = 0;
                obj.n_correct_s_minus_trials = 0;
                obj.n_incorrect_s_minus_trials = 0;
                
                h = onCleanup(@obj.cleanup);
                
                obj.rc2ctl.prepare_acq();
                obj.rc2ctl.start_acq();
                
                obj.running = true;
                
                % keep looping for as long as stimuli are presented
                while true
                    
                    % wait for bytes from stimulus computer
                    while obj.tcp_client.NumBytesAvailable == 0
                        pause(0.001);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    
                    % get protocol type 's_plus' or 's_minus'
                    obj.current_stimulus_type = obj.tcp_client.readline();
                    
                    % make sure return value is s_plus or s_minus
                    assert(ismember(obj.current_stimulus_type, {'s_plus', 's_minus'}), ...
                        'Unknown protocol type');
                    
                    % next trial
                    obj.current_trial = obj.current_trial + 1;
                    
                    % if 's_minus' trial then we suppress the giving of reward
                    if strcmp(obj.current_stimulus_type, 's_minus')
                        obj.rc2ctl.lick_detector.enable_reward = false;
                    else
                        obj.rc2ctl.lick_detector.enable_reward = true;
                    end
                    
                    % reset the lick
                    obj.rc2ctl.lick_detector.reset_window();
                    
                    % send signal back to visual stimulus computer
                    %   assumes that vis stim computer is waiting...
                    obj.tcp_client.writeline('start_trial');
                    
                    % wait for update of licking variable
                    while obj.lick_detected == -1
                        pause(0.001);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    
                    % store stimulus type
                    obj.stimulus_type_list{obj.current_trial} = obj.current_stimulus_type;
                    
                    % if the protocol is S+, then lick is correct response
                    if strcmp(obj.current_stimulus_type, 's_plus')
                        
                        if obj.lick_detected
                            % correct S+ trial
                            obj.is_correct(obj.current_trial) = true;
                            obj.n_correct_s_plus_trials = obj.n_correct_s_plus_trials + 1;
                        else
                            % incorrect S+ trial
                            obj.is_correct(obj.current_trial) = false;
                            obj.n_incorrect_s_plus_trials = obj.n_incorrect_s_plus_trials + 1;
                        end
                        
                    elseif strcmp(obj.current_stimulus_type, 's_minus')
                        
                        if obj.lick_detected
                            % incorrect S- trial
                            obj.is_correct(obj.current_trial) = false;
                            obj.n_incorrect_s_minus_trials = obj.n_incorrect_s_minus_trials + 1;
                        else
                            % correct S- trial
                            obj.is_correct(obj.current_trial) = true;
                            obj.n_correct_s_minus_trials = obj.n_correct_s_minus_trials + 1;
                        end
                    end
                    
                    obj.lick_detected = -1;
                end
            end
            % let cleanup handle the stopping
        end
        
        
        
        function stop(obj)
            
            obj.abort = true;
        end
        
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.tcp_client.writeline('rc2_stopping');
            delete(obj.tcp_client);
            obj.rc2ctl.stop_acq();
        end
        
        
        
        function lick_notification(obj, ~, ~)
            
            obj.lick_detected = obj.rc2ctl.lick_detector.lick_occurred_in_window;
        end
    end
end
