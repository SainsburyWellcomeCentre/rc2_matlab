classdef rc2guiController < handle
% rc2guiController Main class for controlling the GUI
%
%   rc2guiController Properties:
%         setup                 - object of class RC2Controller
%         view                  - object of class rc2guiView
%         move_to_pos           - value containing position to move to on move_to operation
%         reward_distance       - value containing travel distance after which reward is given during training
%         reward_location       - value containing position the reward is given during training
%                                 NOTE: reward_distance and reward_location
%                                 together determine the start position during training 
%         n_loops               - number of training trials to perform
%         back_distance         - distance the stage can travel back before training trial is stopped
%         condition             - 'closed_loop' or 'open_loop'
%         stage_limits          - stage position limits specified in config.stage.max_limits
%         speed_limits          - max and min allowable speed limits *during move_to operation*
%         training_seq          - sequence (ProtocolSequence class) of trial classes for a training
%         experiment_seq        - sequence (ProtocolSequence class) of trial classes for an experiment
%         current_script        - the current file to run when 'Run Experiment' is pushed
%         preview_on            - is the preview display on
%         sequence_on           - not used?
%
%   rc2guiController Methods:
%       delete                  - destructor
%       toggle_acquisition      - stop/start preview of data
%       give_reward             - give a reward
%       changed_reward_duration - reward duration was changed
%       change_reward_location  - reward location was changed
%       change_reward_distance  - reward distance was changed
%       closed_loop             - set training to closed loop
%       open_loop               - set training to open loop
%       block_treadmill         - block the treadmill
%       unblock_treadmill       - unblock the treadmill
%       pump_on                 - turn the pump on
%       pump_off                - turn the pump off
%       toggle_sound            - stop/start the sound
%       enable_sound            - enable the sound module
%       disable_sound           - disable the sound module
%       changed_move_to_pos     - move_to value changed in GUI
%       changed_speed           - speed value changed in GUI
%       move_to                 - move_to button pushed
%       home_soloist            - home the linear stage
%       reset_soloist           - reset the linear stage
%       stop_soloist            - aborts an operation on the Soloist
%       set_script              - sets path to an experiment file to run
%       set_save_to             - set "save to" directory
%       set_file_prefix         - after set file prefix string
%       set_file_suffix         - after set file suffix string
%       set_file_index          - after set file index string
%       enable_save             - enable saving of data
%       start_training          - start/stop a training sequence
%       start_experiment        - start/stop an experimental sequence
%       print_error             - print an error to the GUI
%       acknowledge_error       - acknowldge an error on the GUI
%       training_trial_updated  - a trial of a training sequence has finished
%       forward_training_trial_updated - the trial of the last training sequence was forward
%       backward_training_trial_updated - the trial of the last training sequence was backward
%       experiment_trial_updated - a trial of an experiment sequence has finished
%
%   Creates the GUI for control of the setup.
%
%   Upon creation buttons and edit boxes are greyed/disabled until the
%   'HOME' button is pushed. This button homes the linear stage if it has
%   not already been homed. Then all UI elements are displayed and enabled.
%
%   TODO: `current_script` and `set_script` are not named correctly as it
%         is a function that is run.

    properties (SetAccess = private)
        
        setup
        view
    end
    
    properties
        
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
        % rc2guiController
        %
        %   rc2guiController(CTL, CONFIG) setups the GUI and creates the
        %   main object for controlling the GUI. CTL is an object for the
        %   main setup of class RC2Controller, and CONFIG is the
        %   configuration structure for the setup.
        
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
        %%delete Destructor
        
            delete(obj.view);
        end
        
        
        
        function toggle_acquisition(obj)
        %%toggle_acquisition Stop/start preview of data
        %
        %   toggle_acquisition() starts or stops the acquisition preview of
        %   data (display of analog inputs).
        
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
        %%give_reward Give a reward
        %
        %   give_reward()
        
            obj.setup.give_reward()
        end
        
        
        
        function changed_reward_duration(obj, h_obj)
        %%changed_reward_duration Callback for when the reward duration has
        %%been changed in the GUI.
        %
        %   changed_reward_duration(UI_HANDLE) is called when the GUI
        %   element for reward duration is updated. UI_HANDLE is a handle
        %   to the edit box.
        
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
        %%change_reward_location Callback for when the reward location has
        %%been changed in the GUI.
        %
        %   change_reward_location(UI_HANDLE) is called when the GUI
        %   element for reward location is updated. UI_HANDLE is a handle
        %   to the edit box.
        
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
        %%change_reward_distance Callback for when the reward distance has
        %%been changed in the GUI.
        %
        %   change_reward_distance(UI_HANDLE) is called when the GUI
        %   element for reward distance is updated. UI_HANDLE is a handle
        %   to the edit box.
        
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
        %%closed_loop Callback for when the closed loop toggle button has
        %%been pressed.
        %
        %   closed_loop(UI_HANDLE) is called when the GUI element for when
        %   the closed loop toggle button has been pressed. UI_HANDLE is
        %   a handle to the toggle button.
        
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
        %%open_loop Callback for when the open loop toggle button has
        %%been pressed.
        %
        %   open_loop(UI_HANDLE) is called when the GUI element for when
        %   the open loop toggle button has been pressed. UI_HANDLE is
        %   a handle to the toggle button.
        
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
        %%block_treadmill Block the treadmill
        %
        %   block_treadmill()
        
            obj.setup.block_treadmill()
        end
        
        
        
        function unblock_treadmill(obj)
        %%unblock_treadmill Unblock the treadmill
        %
        %   unblock_treadmill()
        
            obj.setup.unblock_treadmill()
        end
        
        
        
        function pump_on(obj)
        %%pump_on Turn the pump on
        %
        %   pump_on()
        
            obj.setup.pump_on();
        end
        
        
        
        function pump_off(obj)
        %%pump_off Turn the pump off
        %
        %   pump_off()
        
            obj.setup.pump_off();
        end
        
        
        
        function toggle_sound(obj)
        %%toggle_sound Start/stop the sound
        %
        %   toggle_sound()
        
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
        %%enable_sound Enable the sound module
        %
        %   enable_sound()
        
            obj.setup.sound.enable();
        end
        
        
        
        function disable_sound(obj)
        %%disable_sound Disable the sound module
        %
        %   disable_sound()
        
            obj.setup.sound.disable();
        end
        
        
        
        function changed_move_to_pos(obj, h_obj)
        %%changed_move_to_pos Callback for when the "move to" value has
        %%been changed in the GUI.
        %
        %   changed_move_to_pos(UI_HANDLE) is called when the GUI
        %   element for "move to" position is updated. UI_HANDLE is a
        %   handle to the edit box.
        
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
        %%changed_speed Callback for when the speed value has
        %%been changed in the GUI.
        %
        %   changed_speed(UI_HANDLE) is called when the GUI
        %   element for speed value is updated. UI_HANDLE is a
        %   handle to the edit box.
        
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
        %%move_to Move the stage
        %
        %   move_to() moves the stage to the position defined in the
        %   "move to" GUI edit box.
        %
        %   See also: Soloist.move_to
        
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
        %%home_soloist Homes the linear stage
        %
        %   home_soloist()
        %
        %   See also: Soloist.home
        
            obj.setup.home_soloist();
            obj.view.show_ui_after_home();
        end
        
        
        
        function reset_soloist(obj)
        %%reset_soloist Resets the linear stage
        %
        %   reset_soloist()
        %
        %   See also: Soloist.reset
        
            obj.setup.soloist.reset();
        end
        
        
        
        function stop_soloist(obj)
        %%stop_soloist Aborts an operation on the Soloist
        %
        %   stop_soloist()
        %
        %   See also: Soloist.abort
        
            obj.setup.soloist.abort();
        end
        
        
        
        function set_script(obj)
        %%set_script Sets path to an experiment file to run
        %
        %   set_script() sets the full path to a file to run when 'Run
        %   Experiment' is pushed.
        %
        %   The file should contain a MATLAB function which returns a
        %   ProtocolSequence object, containing a set of trial classes to
        %   execute.
        
            start_dir = pwd;
            [user_file, pathname] = uigetfile(fullfile(start_dir, '*.m'), 'Choose script to run...');
            
            if ~user_file; return; end
            
            obj.current_script = fullfile(pathname, user_file);
            obj.view.script_updated();
        end
        
        
        
        function set_save_to(obj)
        %%set_save_to Set the "save to" directory
        %
        %   set_save_to() opens a dialog in which to choose a directory to
        %   save data to.
        
            start_dir = obj.setup.saver.save_to;
            user_dir = uigetdir(start_dir, 'Choose save directory...');
            
            if ~user_dir; return; end
            
            obj.setup.set_save_save_to(user_dir);
            obj.view.save_to_updated();
        end
        
        
        
        function set_file_prefix(obj, h_obj)
        %%set_file_prefix Callback for when file prefix edit box has been
        %%modified.
        %
        %   set_file_prefix(UI_HANDLE) is called when the GUI element for
        %   when file prefix edit box has been modified. UI_HANDLE is
        %   a handle to the toggle button.
        
            str = get(h_obj, 'string');
            obj.setup.set_save_prefix(str)
            obj.view.prefix_updated();
        end
        
        
        
        function set_file_suffix(obj, h_obj)
        %%set_file_suffix Callback for when file suffix edit box has been
        %%modified.
        %
        %   set_file_suffix(UI_HANDLE) is called when the GUI element for
        %   when file suffix edit box has been modified. UI_HANDLE is
        %   a handle to the toggle button.
        
            str = get(h_obj, 'string');
            obj.setup.set_save_suffix(str)
            obj.view.suffix_updated();
        end
        
        
        
        function set_file_index(obj, h_obj)
        %%set_file_index Callback for when file index edit box has been
        %%modified.
        %
        %   set_file_index(UI_HANDLE) is called when the GUI element for
        %   when file index edit box has been modified. UI_HANDLE is
        %   a handle to the toggle button.
        
            val = str2double(get(h_obj, 'string'));
            obj.setup.set_save_index(val);
            obj.view.index_updated();
        end
        
        
        
        function enable_save(obj, h_obj)
        %%enable_save Callback for when the "save" checkbox has
        %%been pressed.
        %
        %   enable_save(UI_HANDLE) is called when the GUI element for when
        %   the "save" checkbox has been pressed. UI_HANDLE is
        %   a handle to the toggle button.
        
            val = get(h_obj, 'value');
            obj.setup.set_save_enable(val);
            obj.view.enable_updated();
        end
        
        
        
        function start_training(obj)
        %%start_training Start/stop a training sequence
        %
        %   start_training() starts a training sequence if one is not
        %   already running. If one is running, it stops the sequence.
        %   Also toggles the text on the 'Start Training' button.
        
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
                forward_only = get(obj.view.handles.checkbox_forward_only, 'value');
                
                if ~isempty(obj.training_seq)
                    delete(obj.training_seq)
                end
                
                % create a protocol sequence
                bd = min(obj.back_distance, max(obj.stage_limits) - (reward_location + reward_distance));
                
                obj.training_seq = setup_training_sequence(obj.setup, closed_loop, reward_location, ...
                    reward_distance, bd, obj.n_loops, forward_only);
                
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
        %%start_experiment Start/stop a experimental sequence
        %
        %   start_experiment() starts a experimental sequence if one is not
        %   already running. If one is running, it stops the sequence.
        %   Also toggles the text on the 'Start Experiment' button.
        %
        %   Starts the experimental sequence defined in the file referenced
        %   to `current_script`.
        %
        %   See also: `set_script`
        %   See also README in protocols directory.
        
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
        %%print_error Print an error to the GUI
        %
        %   print_error(MESSAGE) prints the string in MESSAGE to the GUI.
        
            set(obj.view.handles.text_error_msg, 'string', sprintf('Error: %s', msg));
            set(obj.view.handles.pushbutton_acknowledge_error, 'visible', 'on');
        end
        
        
        
        function acknowledge_error(obj)
        %%acknowledge_error Acknowldge an error on the GUI
        %
        %   acknowledge_error() is called after the 'OK' button is pressed
        %   and removes the error message and 'OK' button.
        
            set(obj.view.handles.text_error_msg, 'string', '');
            set(obj.view.handles.pushbutton_acknowledge_error, 'visible', 'off');
        end
        
        
        
        function training_trial_updated(obj, ~, ~)
        %%training_trial_updated A trial of a training sequence has finished
        %
        %   training_trial_updated() called after a trial in a training
        %   sequence has finished.
        
            str = sprintf('%i', obj.training_seq.current_trial);
            set(obj.view.handles.edit_training_trial, 'string', str);
        end
        
        
        
        function forward_training_trial_updated(obj, ~, ~)
        %%forward_training_trial_updated The trial of the last training sequence was forward
        %
        %   forward_training_trial_updated() called after a trial in a training
        %   sequence has finished and moved forward.
        
            str = sprintf('%i', obj.training_seq.forward_trials);
            set(obj.view.handles.text_n_forwards, 'string', str);
        end
        
        
        
        function backward_training_trial_updated(obj, ~, ~)
        %%backward_training_trial_updated The trial of the last training sequence was backward
        %
        %   backward_training_trial_updated() called after a trial in a training
        %   sequence has finished and moved backward.
        
            str = sprintf('%i', obj.training_seq.backward_trials);
            set(obj.view.handles.text_n_backwards, 'string', str);
        end
        
        
        
        function experiment_trial_updated(obj, ~, ~)
        %%experiment_trial_updated The trial of the last experiment
        %%sequence has finished
        %
        %   experiment_trial_updated() called after a trial in a experiment
        %   sequence has finished.
        
            str = sprintf('%i', obj.experiment_seq.current_trial);
            set(obj.view.handles.edit_experiment_trial, 'string', str);
        end
    end
end
