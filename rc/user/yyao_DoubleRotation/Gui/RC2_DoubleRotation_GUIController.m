classdef RC2_DoubleRotation_GUIController < handle
    
    properties
        
        setup
        config
        view
        
        move_to_pos             % central stage move_to_pos
        move_to_pos_2           % outer stage move_to_pos
        stage_limits            % [stage min position, stage max position]
        speed_limits
        
        experiment_seq          
        current_script          % current filepath
        
        protocol_gui
    end
    
    properties (SetAccess = private)
        
        preview_on
        sequence_on
    end
    
    
    
    methods
        
        function obj = RC2_DoubleRotation_GUIController(setup, config)   
            
            obj.setup = setup;      
            obj.config = config;    
            obj.stage_limits = config.stage.max_limits;
            obj.speed_limits = config.ensemble.speed_limits;
            obj.move_to_pos = config.stage.start_pos;
            
            obj.view = RC2_DoubleRotation_GUIView(obj);
        end
        
        
        function delete(obj)    
            delete(obj.view);
        end
        
      
        %% Stage callback
        
        function changed_move_to_pos(obj)            % Central Stage Panel Position Edit Field Callback Function
            val = obj.view.handles.PositionEditField.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)   
                
                msg = sprintf('"move to" position must be a number\n');  
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.PositionEditField.Value = sprintf('%.1f',obj.move_to_pos);
                return
            end
            
            
            if val > max(obj.stage_limits) || val < min(obj.stage_limits)  
                
                msg = sprintf('"move to" position must be between [%.2f, %.2f]\n', ...
                    min(obj.stage_limits), max(obj.stage_limits));
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                obj.view.handles.PositionEditField.Value = sprintf('%.1f',obj.move_to_pos);
                return
            end
            
            obj.move_to_pos = val; 
        end
        
        function changed_move_to_pos_2(obj)            % Outer Stage Panel Position Edit Field Callback Function
            val = obj.view.handles.PositionEditField_2.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)   
                
                msg = sprintf('"move to" position must be a number\n');  
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.PositionEditField_2.Value = sprintf('%.1f',obj.move_to_pos_2);
                return
            end
            
            
            if val > max(obj.stage_limits) || val < min(obj.stage_limits)  
                
                msg = sprintf('"move to" position must be between [%.2f, %.2f]\n', ...
                    min(obj.stage_limits), max(obj.stage_limits));
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                obj.view.handles.PositionEditField_2.Value = sprintf('%.1f',obj.move_to_pos_2);
                return
            end
            
            obj.move_to_pos_2 = val;  
        end

        function changed_speed(obj)             % Central Stage Panel Speed Edit Field Callback Function
            val = obj.view.handles.SpeedEditField.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)
                 
                msg = sprintf('speed must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
            
            
            if val < min(obj.speed_limits) || val > max(obj.speed_limits)
                
                msg = sprintf('speed must be between [%.2f, %.2f]\n', min(obj.speed_limits), max(obj.speed_limits));
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
        end

        function changed_speed_2(obj)           % Outer Stage Panel Speed Edit Field Callback Function
            val = obj.view.handles.SpeedEditField_2.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)
                 
                msg = sprintf('speed must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField_2.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
            
            
            if val < min(obj.speed_limits) || val > max(obj.speed_limits)
                
                msg = sprintf('speed must be between [%.2f, %.2f]\n', min(obj.speed_limits), max(obj.speed_limits));
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField_2.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
        end
        
        function move_to(obj,leave_enabled)                   % Stage Panel MOVE TO Button Callback Function, move stage to position

            if all(isnan(obj.setup.ensemble.target_axes)), return, end
            
            VariableDefault('leave_enabled', false);

            pos = NaN([1,length(obj.setup.ensemble.all_axes)]);
            speed = NaN([1,length(obj.setup.ensemble.all_axes)]);
            if ismember(obj.setup.ensemble.all_axes(1),obj.setup.ensemble.target_axes)
                pos(1) = obj.view.handles.PositionEditField.Value;          
                speed(1) = obj.view.handles.SpeedEditField.Value;           
                if ~isnumeric(pos(1)) || isinf(pos(1)) || isnan(pos(1))
                    error('position is not numeric')
                end
                if ~isnumeric(speed(1)) || isinf(speed(1)) || isnan(speed(1))
                    error('speed is not numeric')
                end
            end
            if ismember(obj.setup.ensemble.all_axes(2),obj.setup.ensemble.target_axes)
                pos(2) = obj.view.handles.PositionEditField_2.Value;
                speed(2) = obj.view.handles.SpeedEditField_2.Value;
                if ~isnumeric(pos(2)) || isinf(pos(2)) || isnan(pos(2))
                    error('position is not numeric')
                end
                if ~isnumeric(speed(2)) || isinf(speed(2)) || isnan(speed(2))
                    error('speed is not numeric')
                end
            end
            obj.setup.move_to(pos, speed,leave_enabled);     
        end
        
        
        function home_ensemble(obj,leave_enabled)              % Stage Panel HOME Button Callback Function
            obj.setup.home_ensemble(leave_enabled);          
        end
        
        
        function reset_ensemble(obj)             % Stage Panel RESET Button Callback Function
            obj.setup.ensemble.reset();          
        end
        
        function stop_ensemble(obj)              % Stage Panel STOP Button Callback Function
            obj.setup.ensemble.abort();          
        end
        
        function set_target_axes(obj,axes)      % set which axes to opperate       
            obj.setup.set_target_axes(axes);           
        end
        
        %% Experiment callback
        
        function set_script(obj)                % Experiment Panel ... Button Callback Function
            
            start_dir = pwd;                    
            [user_file, pathname] = uigetfile(fullfile(start_dir, '*.m'), 'Choose script to run...');
            if ~user_file; return; end
            
            obj.current_script = fullfile(pathname, user_file);
            obj.view.script_updated();
            [~, obj.setup.saver.index,~] = fileparts(obj.current_script);  
            obj.view.index_updated();
        end
        
        
        function start_experiment(obj)                  % Experiment Panel START EXPERIMENT Button Callback Function
            
            if obj.preview_on
                msg = sprintf('stop preview before starting experiment\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % check that current script is selected
            if isempty(obj.current_script)
                
                msg = sprintf('no script selected\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % check that current script exists.
            if ~exist(obj.current_script, 'file')
                
                msg = sprintf('script selected doesn''t exist\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % if experiment sequence is empty, we haven't started a
            % experiment sequence yet
            % else the we set is_running to the status of the training seq
            if isempty(obj.experiment_seq)
                is_running = false;
            else
                is_running = obj.experiment_seq.running;
            end
            
            % if training sequence hasn't been started, start it, else stop
            % it
            if is_running
                
                % stop the training sequence and reset the button
                obj.experiment_seq.stop();
                obj.view.handles.StartExperimentButton.Value = 0;
                obj.view.handles.StartExperimentButton.Text = 'Start Experiment';
            else
                % reset tcp clients
%                 obj.setup.reset_communication(obj.config);

                % send animal, session, protocol name to remote host
                animal_id = obj.setup.saver.prefix;
                session = obj.setup.saver.suffix;
                protocol = obj.setup.saver.index;

                obj.setup.communication.setup();
                cmd = sprintf('%s:%s_%s_%s', protocol, animal_id, session, protocol);   
                fprintf('sending protocol information to visual stimulus computer\n');
                obj.setup.communication.tcp_client.writeline(cmd);  
                
                % block until we get a response from remote host
                fprintf('waiting for visual stimulus computer to finish preparing\n');
                while obj.setup.communication.tcp_client.NumBytesAvailable == 0
                end
                return_message = obj.setup.communication.tcp_client.readline();   

                if strcmp(return_message, 'abort')   
                    error('return signal from visual stimulus computer was to abort'); 
                    % TODO：添加终止后reset
                elseif ~strcmp(return_message, 'visual_stimulus_setup_complete')
                    error('unknown return signal from visual stimulus computer');   
                end
                
                
                
                % generate protocol sequence
                [~, fname] = fileparts(obj.current_script);
                [protocolconfig, obj.experiment_seq] = feval(fname, obj.setup, obj.config, obj.view);  
                obj.config.lick_detect.enable                   = protocolconfig.lick_detect.enable;
                obj.config.lick_detect.lick_threshold           = protocolconfig.lick_detect.lick_threshold;
                obj.config.lick_detect.n_windows                = protocolconfig.lick_detect.n_windows;
                obj.config.lick_detect.window_size_ms           = protocolconfig.lick_detect.window_size_ms;
                obj.config.lick_detect.n_lick_windows           = protocolconfig.lick_detect.n_lick_windows;
                obj.config.lick_detect.n_consecutive_windows    = protocolconfig.lick_detect.n_consecutive_windows;
                obj.config.lick_detect.detection_trigger_type   = protocolconfig.lick_detect.detection_trigger_type;
                obj.config.lick_detect.delay                    = protocolconfig.lick_detect.delay;
                
                % reinitialize the lick detection module....
                obj.setup.lick_detector = LickDetect_DoubleRotation(obj.setup, obj.config);   

                % start the Go/No-go gui... this seems to take a long time and is
                % non-blocking
                obj.protocol_gui = GoNogo_DoubleRotation_GUIController(obj.experiment_seq);  
                
                obj.view.handles.StartExperimentButton.Value = 1;
                obj.view.handles.StartExperimentButton.Text = 'Stop Experiment';
%                 addlistener(obj.experiment_seq, 'current_trial', 'PostSet', @(src, evnt)obj.experiment_trial_updated(src, evnt));
                
                % start experiment
                fprintf('start experiment\n');
                obj.experiment_seq.run(protocolconfig.enable_vis_stim);   
                
                obj.experiment_seq = [];
                delete(obj.protocol_gui);
                obj.view.handles.StartExperimentButton.Value = 0;
                obj.view.handles.StartExperimentButton.Text = 'Start Experiment';
                
                
            end
        end
        
        

        
        
        %% Saving callback
        
        function set_save_to(obj)                   % Saving Panel ... Button Callback Function。
            start_dir = obj.setup.saver.save_to;
            user_dir = uigetdir(start_dir, 'Choose save directory...');     
            if ~user_dir; return; end
            
            obj.setup.set_save_save_to(user_dir);   
            obj.view.save_to_updated();             % 
        end
        
        
        function set_file_path(obj)                 % Saving Panel SavePathEditField Edit Field Callback Function
            str = obj.view.handles.SavePathEditField.Value;
            obj.setup.set_save_save_to(str);        
            obj.view.save_to_updated();             % 
        end
        
        
        function set_file_prefix(obj)        % Saving Panel AnimalID Edit Field Callback Function
%             str = get(h_obj, 'string');
            str = obj.view.handles.AnimalIDEditField.Value;
            obj.setup.set_save_prefix(str)          
            obj.view.prefix_updated();
        end
        
        
        function set_file_suffix(obj)        % Saving Panel Session Edit Field Callback Function
%             str = get(h_obj, 'string');
            str = obj.view.handles.SessionEditField.Value;
            obj.setup.set_save_suffix(str)          
            obj.view.suffix_updated();
        end
        
        
        function enable_save(obj, h_obj)            % Saving Panel Save Callback Function
            val = get(h_obj, 'value');
            obj.setup.set_save_enable(val);
            obj.view.enable_updated();
        end
        
        
        %% Pump callback
        
        function give_reward(obj)                               % Pump Panel REWARD Button Callback Function
            obj.setup.give_reward()                             
        end
        
        
        function changed_reward_duration(obj)            % Pump Panel Duration Edit Field Callback Function
            
            val = str2double(obj.view.handles.DurationEditField.Value);
            
            if ~isnumeric(val) || isinf(val) || isnan(val)
                msg = sprintf('reward duration must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_reward_duration', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.DurationEditField.Value = sprintf('%.1f',obj.setup.reward.duration);
                return
            end
            
            status = obj.setup.reward.set_duration(val);        
            if status == -1
                
                msg = sprintf('reward duration must be between %.1f and %.1f\n', ...
                    obj.setup.reward.min_duration, obj.setup.reward.max_duration);
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_reward_duration', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.DurationEditField.Value = sprintf('%.1f',obj.setup.reward.duration);      
                return
            end
        end
        
        
        function pump_on(obj)                       % Pump Panel ON Button Callback Function，
        %%PUMP_ON(obj)
        %  Turn the pump on. To start filling a chamber for example.
            %  when Button is pressed, obj.view.handles.PumpONButton.Value = 1
            if obj.setup.pump.state
                obj.setup.pump_off();                          
                obj.view.handles.PumpONButton.Text = 'ON';
                obj.view.handles.PumpONButton.Value = 0;
            else
                obj.setup.pump_on();                            
                obj.view.handles.PumpONButton.Text = 'OFF';
                obj.view.handles.PumpONButton.Value = 1;
            end
        end
        
        %% Sound callback
        
        function toggle_sound(obj)                  % Sound Panel PLAY Button Callback Function
            if ~obj.setup.sound.enabled
                return
            end
            if obj.setup.sound.state               
                obj.setup.stop_sound();
                obj.view.handles.PlaySoundButton.Text = 'PLAY';
                obj.view.handles.PlaySoundButton.Value = 0;
            else                                  
                obj.setup.play_sound();              
                obj.view.handles.PlaySoundButton.Text = 'STOP';
                obj.view.handles.PlaySoundButton.Value = 1;
            end
        end
        
        
        function enable_sound(obj)                          % Sound Panel Enable Callback Function
            obj.setup.sound.enable();
            obj.view.handles.PlaySoundButton.Enable = 'on';
        end
        
        
        function disable_sound(obj)                         % Sound Panel Disable Callback Function
            obj.setup.sound.disable();
            obj.view.handles.PlaySoundButton.Enable = 'off';
        end
        
        %% AI Preview callback
        function toggle_acquisition(obj)                % AI Preview Panel PREVIEW Button Callback Function
            % if a acquisition with data-saving is running don't do
            % anything.
            if obj.setup.acquiring; return; end         
            
            if obj.setup.acquiring_preview              
                obj.setup.stop_preview()
                obj.view.handles.PreviewButton.Text = 'PREVIEW';
                obj.view.handles.PreviewButton.Value = 0;
                obj.preview_on = false;
            else                                        
                obj.setup.start_preview()
                obj.view.handles.PreviewButton.Text = 'STOP';
                obj.view.handles.PreviewButton.Value = 1;
                obj.preview_on = true;
            end
        end

        
        %%
        function print_error(obj, msg)
            obj.view.handles.messageLable.Text = sprintf('Error: %s', msg);
            obj.view.handles.messageButton.Visible = 'on';
        end
        
        
        function acknowledge_error(obj)
            obj.view.handles.messageLable.Text = '';
            obj.view.handles.messageButton.Visible = 'off';
        end
        
    end
end