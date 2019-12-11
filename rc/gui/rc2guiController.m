classdef rc2guiController < handle
    
    properties
        
        setup
        view
        
        move_to_pos
        reward_distance
        reward_location
        n_loops = 200
        back_distance = 50
        condition
        
        stage_limits
        speed_limits
        
        training_seq
        experiment_seq
        
        current_script
    end
    
    properties (SetAccess = private)
        
        preview_on
        sequence_on
    end
    
    
    
    methods
        
        function obj = rc2guiController(setup, config)
            
            obj.setup = setup;
            obj.stage_limits = config.stage.max_limits;
            
            obj.speed_limits = [10, 500]; %TODO: config?
            
            obj.move_to_pos = config.stage.start_pos;
            
            obj.condition = 'closed_loop'; %TODO: config?
            
            obj.reward_location = 250; %TODO: config?
            obj.reward_distance = 200; %TODO: config?
            
            obj.view = rc2guiView(obj);
        end
        
        
        
        function delete(obj)    
            delete(obj.view);
        end
        
        
        
        function toggle_acquisition(obj)
            % if a acquisition with data-saving is running don't do
            % anything.
            if obj.setup.acquiring; return; end
            
            if obj.setup.acquiring_preview
                obj.setup.stop_preview()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'PREVIEW');
                obj.preview_on = false;
            else
                obj.setup.start_preview()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'STOP');
                obj.preview_on = true;
            end
        end
        
        
        
        function give_reward(obj)
            obj.setup.give_reward()
        end
        
        
        
        function changed_reward_duration(obj, h_obj)
            
            val = str2double(get(h_obj, 'string'));
            
            if ~isnumeric(val) || isinf(val) || isnan(val)
                msg = sprintf('reward duration must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_reward_duration', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_reward_duration, 'string', sprintf('%.1f', obj.setup.reward.duration))
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
                
                set(obj.view.handles.edit_reward_duration, 'string', sprintf('%.1f', obj.setup.reward.duration))
                return
            end
        end
        
        
        
        function change_reward_location(obj, h_obj)
            
            val = str2double(get(h_obj, 'string'));
            
            if ~isnumeric(val) || isinf(val) || isnan(val)
                
                msg = sprintf('reward location must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'change_reward_location', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                set(obj.view.handles.edit_reward_location, 'string', sprintf('%.1f', obj.reward_location))
                return
            end
            
            current_reward_distance = str2double(get(obj.view.handles.edit_reward_distance, 'string'));
            
            % catch value if it is not in the correct range.
            if val < min(obj.stage_limits) || val + current_reward_distance > max(obj.stage_limits)
                
                msg = sprintf('reward location must be between [%.2f, %.2f], given reward distance\n', ...
                        min(obj.stage_limits), max(obj.stage_limits)-current_reward_distance);
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'change_reward_location', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                % reset the edit box to contain the correct value
                set(obj.view.handles.edit_reward_location, 'string', sprintf('%.1f', obj.reward_location))
                
                return
            end
        end
        
        
        
        function change_reward_distance(obj, h_obj)
            
            % get the value just entered into the edit box
            val = str2double(get(h_obj, 'string'));
            
            % if the value is not numeric, infinite or nan = wrong
            if ~isnumeric(val) || isinf(val) || isnan(val)
                
                msg = sprintf('reward distance must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'change_reward_location', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                % reset edit box
                set(obj.view.handles.edit_reward_distance, 'string', sprintf('%.1f', obj.reward_distance))
                return
            end
            
            current_reward_location = str2double(get(obj.view.handles.edit_reward_location, 'string'));
            max_reward_distance = max(obj.stage_limits) - current_reward_location;
            
            if val <= 0 || val >= max_reward_distance % TODO: modify this
                
                msg = sprintf('reward distance must be strictly between [0, %.2f], given reward location\n', max_reward_distance);
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'change_reward_location', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_reward_distance, 'string', sprintf('%.1f', obj.reward_distance))
                return
            end 
        end
        
        
        
        function closed_loop(obj, h_obj)
            val = get(h_obj, 'value');
            if val
                set(obj.view.handles.button_open_loop, 'value', false);
                obj.condition = 'closed_loop';
            else
                if strcmp(obj.condition, 'closed_loop')
                    set(obj.view.handles.button_closed_loop, 'value', true);
                end
            end
        end
        
        
        
        function open_loop(obj, h_obj)
            val = get(h_obj, 'value');
            if val
                set(obj.view.handles.button_closed_loop, 'value', false);
                obj.condition = 'open_loop';
            else
                if strcmp(obj.condition, 'open_loop')
                    set(obj.view.handles.button_open_loop, 'value', true);
                end
            end
        end
        
        
        
        function block_treadmill(obj)
            obj.setup.block_treadmill()
        end
        
        
        
        function unblock_treadmill(obj)
            obj.setup.unblock_treadmill()
        end
        
        
        
        function pump_on(obj)
        %%PUMP_ON(obj)
        %  Turn the pump on. To start filling a chamber for example.
            obj.setup.pump_on();
        end
        
        
        
        function pump_off(obj)
        %%PUMP_OFF(obj)
        %  Turn the pump off. To stop filling for example.
            obj.setup.pump_off();
        end
        
        
        
        function toggle_sound(obj)
            if ~obj.setup.sound.enabled
                return
            end
            if obj.setup.sound.state
                obj.setup.stop_sound()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'PLAY');
            else
                obj.setup.play_sound()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'STOP');
            end
        end
        
        
        
        function enable_sound(obj)
            obj.setup.sound.enable();
        end
        
        
        
        function disable_sound(obj)
            obj.setup.sound.disable();
        end
        
        
        
        function changed_move_to_pos(obj, h_obj)
            
            val = str2double(get(h_obj, 'string'));
            
            if ~isnumeric(val) || isinf(val) || isnan(val)
                
                msg = sprintf('"move to" position must be a number\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_move_to, 'string', sprintf('%.1f', obj.move_to_pos))
                return
            end
            
            
            if val > max(obj.stage_limits) || val < min(obj.stage_limits)
                
                msg = sprintf('"move to" position must be between [%.2f, %.2f]\n', ...
                    min(obj.stage_limits), max(obj.stage_limits));
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_move_to, 'string', sprintf('%.1f', obj.move_to_pos))
                return
            end
            
            obj.move_to_pos = val;
        end
        
        
        
        function changed_speed(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                 
                msg = sprintf('speed must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_speed, 'string', sprintf('%.1f', obj.setup.soloist.default_speed))
                return
            end
            
            
            if val < min(obj.speed_limits) || val > max(obj.speed_limits)
                
                msg = sprintf('speed must be between [%.2f, %.2f]\n', min(obj.speed_limits), max(obj.speed_limits));
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                set(obj.view.handles.edit_speed, 'string', sprintf('%.1f', obj.setup.soloist.default_speed))
                return
            end
        end
        
        
        
        function move_to(obj)
            pos = str2double(get(obj.view.handles.edit_move_to, 'string'));
            if ~isnumeric(pos) || isinf(pos) || isnan(pos)
                error('position is not numeric')
            end
            speed = str2double(get(obj.view.handles.edit_speed, 'string'));
            if ~isnumeric(speed) || isinf(speed) || isnan(speed)
                error('speed is not numeric')
            end
            obj.setup.move_to(pos, speed);
        end
        
        
        
        function home_soloist(obj)
            obj.setup.home_soloist();
            obj.view.show_ui_after_home();
        end
        
        
        
        function reset_soloist(obj)
            obj.setup.soloist.reset();
        end
        
        
        
        function stop_soloist(obj)
            obj.setup.soloist.abort();
        end
        
        
        
        function set_script(obj)
            
            start_dir = pwd;
            [user_file, pathname] = uigetfile(fullfile(start_dir, '*.m'), 'Choose script to run...');
            if ~user_file; return; end
            
            obj.current_script = fullfile(pathname, user_file);
            obj.view.script_updated();
        end
        
        
        function set_save_to(obj)
            start_dir = obj.setup.saver.save_to;
            user_dir = uigetdir(start_dir, 'Choose save directory...');
            if ~user_dir; return; end
            
            obj.setup.set_save_save_to(user_dir);
            obj.view.save_to_updated();
        end
        
        
        
        function set_file_prefix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.set_save_prefix(str)
            obj.view.prefix_updated();
        end
        
        
        
        function set_file_suffix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.set_save_suffix(str)
            obj.view.suffix_updated();
        end
        
        
        
        function set_file_index(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            obj.setup.set_save_index(val);
            obj.view.index_updated();
        end
        
        
        
        function enable_save(obj, h_obj)
            val = get(h_obj, 'value');
            obj.setup.set_save_enable(val);
            obj.view.enable_updated();
        end
        
        
        
        function start_training(obj)
            
            if obj.preview_on
                msg = sprintf('stop preview before starting training\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_training', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % if training sequence is empty, we haven't started a training
            % sequence
            % else the we set is_running to the status of the training seq
            if isempty(obj.training_seq)
                is_running = false;
            else
                is_running = obj.training_seq.running;
            end
            
            % if training sequence hasn't been started, start it, else stop
            % it
            if is_running
                
                % stop the training sequence and reset the button
                obj.training_seq.stop();
                set(obj.view.handles.pushbutton_start_training, 'string', 'START TRAINING')
                
            else
                
                % determine if are we training in closed loop or open loop
                closed_loop = strcmp(obj.condition, 'closed_loop');
                
                % read reward location and distances
                reward_location = str2double(get(obj.view.handles.edit_reward_location, 'string')); %#ok<*PROP>
                reward_distance = str2double(get(obj.view.handles.edit_reward_distance, 'string'));
                
                
                if ~isempty(obj.training_seq)
                    delete(obj.training_seq)
                end
                
                % create a protocol sequence
                obj.training_seq = setup_training_sequence(obj.setup, closed_loop, reward_location, ...
                    reward_distance, obj.back_distance, obj.n_loops);
                set(obj.view.handles.pushbutton_start_training, 'string', 'STOP TRAINING')
                addlistener(obj.training_seq, 'current_trial', 'PostSet', @(src, evnt)obj.training_trial_updated(src, evnt));
                addlistener(obj.training_seq, 'forward_trials', 'PostSet', @(src, evnt)obj.forward_training_trial_updated(src, evnt));
                addlistener(obj.training_seq, 'backward_trials', 'PostSet', @(src, evnt)obj.backward_training_trial_updated(src, evnt));
                
                % run the training sequence
                obj.training_seq.run()
                set(obj.view.handles.pushbutton_start_training, 'string', 'START TRAINING')
            end
        end
        
        
        function start_experiment(obj)
            
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
                set(obj.view.handles.pushbutton_start_experiment, 'string', 'START EXPERIMENT')
            else
                
                % 
                [~, fname] = fileparts(obj.current_script);
                
                obj.experiment_seq = feval(fname, obj.setup);
                
                set(obj.view.handles.pushbutton_start_experiment, 'string', 'STOP')
                addlistener(obj.experiment_seq, 'current_trial', 'PostSet', @(src, evnt)obj.experiment_trial_updated(src, evnt));
                
                obj.experiment_seq.run()
                set(obj.view.handles.pushbutton_start_experiment, 'string', 'START EXPERIMENT')
            end
        end
        
        
        
        function print_error(obj, msg)
            set(obj.view.handles.text_error_msg, 'string', sprintf('Error: %s', msg));
            set(obj.view.handles.pushbutton_acknowledge_error, 'visible', 'on');
        end
        
        
        function acknowledge_error(obj)
            set(obj.view.handles.text_error_msg, 'string', '');
            set(obj.view.handles.pushbutton_acknowledge_error, 'visible', 'off');
        end
        
        
        function training_trial_updated(obj, ~, ~)
            str = sprintf('%i', obj.training_seq.current_trial);
            set(obj.view.handles.edit_training_trial, 'string', str);
        end
        
        
        function forward_training_trial_updated(obj, ~, ~)
            str = sprintf('%i', obj.training_seq.forward_trials);
            set(obj.view.handles.text_n_forwards, 'string', str);
        end
        
        
        function backward_training_trial_updated(obj, ~, ~)
            str = sprintf('%i', obj.training_seq.backward_trials);
            set(obj.view.handles.text_n_backwards, 'string', str);
        end
        
        
        function experiment_trial_updated(obj, ~, ~)
            str = sprintf('%i', obj.experiment_seq.current_trial);
            set(obj.view.handles.edit_experiment_trial, 'string', str);
        end
    end
end