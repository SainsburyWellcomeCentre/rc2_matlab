classdef rc2guiView < handle
    
    properties
        
        controller
        gui
        handles
    end
    
    
    
    methods
        
        function obj = rc2guiView(controller)
            
            obj.controller = controller;
            obj.gui = rc2guiGUI(obj.controller);
            obj.handles = guidata(obj.gui);
            
            set(obj.handles.edit_move_to, 'string', sprintf('%.1f', obj.controller.move_to_pos));
            set(obj.handles.edit_speed, 'string', sprintf('%.1f', obj.controller.setup.soloist.default_speed));
            set(obj.handles.edit_reward_duration, 'string', sprintf('%i', obj.controller.setup.reward.duration));
            set(obj.handles.edit_reward_distance, 'string', sprintf('%i', obj.controller.reward_distance));
            set(obj.handles.edit_reward_location, 'string', sprintf('%i', obj.controller.reward_location));
            set(obj.handles.button_closed_loop, 'value', strcmp(obj.controller.condition, 'closed_loop'));
            set(obj.handles.button_open_loop, 'value', strcmp(obj.controller.condition, 'open_loop'));
            set(obj.handles.button_enable_sound, 'value', obj.controller.setup.sound.enabled);
            set(obj.handles.button_disable_sound, 'value', ~obj.controller.setup.sound.enabled);
            set(obj.handles.pushbutton_acknowledge_error, 'visible', 'off');
            set(obj.handles.edit_training_trial, 'string', '0');
            set(obj.handles.edit_experiment_trial, 'string', '0');
            
            save_to = obj.controller.setup.saver.save_to;
            prefix = obj.controller.setup.saver.prefix;
            suffix = obj.controller.setup.saver.suffix;
            index = obj.controller.setup.saver.index;
            enable = obj.controller.setup.saver.enable;
            
            set(obj.handles.edit_save_to, 'string', save_to);
            set(obj.handles.edit_file_prefix, 'string', prefix);
            set(obj.handles.edit_file_suffix, 'string', suffix);
            set(obj.handles.edit_file_index, 'string', index);
            set(obj.handles.checkbox_enable_save, 'value', enable);
            
            addlistener(obj.controller.setup.saver, 'save_to', 'PostSet', @(src, evnt)obj.save_to_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'prefix', 'PostSet', @(src, evnt)obj.prefix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'suffix', 'PostSet', @(src, evnt)obj.suffix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'index', 'PostSet', @(src, evnt)obj.index_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'enable', 'PostSet', @(src, evnt)obj.enable_updated(src, evnt));
            addlistener(obj.controller.setup, 'acquiring_preview', 'PostSet', @(src, evnt)obj.acquiring_updated(src, evnt));
            addlistener(obj.controller.setup.reward, 'duration', 'PostSet', @(src, evnt)obj.reward_duration_updated(src, evnt));
            addlistener(obj.controller.setup.sound, 'enabled', 'PostSet', @(src, evnt)obj.sound_enabled(src, evnt));
            
            obj.hide_ui();
        end
        
        
        function hide_ui(obj)
            
            set(obj.handles.edit_move_to, 'enable', 'off');
            set(obj.handles.edit_speed, 'enable', 'off');
            set(obj.handles.pushbutton_move_to, 'enable', 'off');
            set(obj.handles.pushbutton_reset, 'enable', 'off');
            set(obj.handles.edit_reward_location, 'enable', 'off');
            set(obj.handles.edit_reward_distance, 'enable', 'off');
            set(obj.handles.pushbutton_start_training, 'enable', 'off');
            set(obj.handles.button_closed_loop, 'enable', 'off');
            set(obj.handles.button_open_loop, 'enable', 'off');
            set(obj.handles.pushbutton_script, 'enable', 'off');
            set(obj.handles.pushbutton_start_experiment, 'enable', 'off');
            set(obj.handles.pushbutton_change_save_to, 'enable', 'off');
            set(obj.handles.edit_file_prefix, 'enable', 'off');
            set(obj.handles.edit_file_suffix, 'enable', 'off');
            set(obj.handles.edit_file_index, 'enable', 'off');
            set(obj.handles.checkbox_enable_save, 'enable', 'off');
        end
        
        
        function show_ui_after_home(obj)
            
            set(obj.handles.edit_move_to, 'enable', 'on');
            set(obj.handles.edit_speed, 'enable', 'on');
            set(obj.handles.pushbutton_move_to, 'enable', 'on');
            set(obj.handles.pushbutton_reset, 'enable', 'on');
            set(obj.handles.edit_reward_location, 'enable', 'on');
            set(obj.handles.edit_reward_distance, 'enable', 'on');
            set(obj.handles.pushbutton_start_training, 'enable', 'on');
            set(obj.handles.button_closed_loop, 'enable', 'on');
            set(obj.handles.button_open_loop, 'enable', 'on');
            set(obj.handles.pushbutton_script, 'enable', 'on');
            set(obj.handles.pushbutton_start_experiment, 'enable', 'on');
            set(obj.handles.pushbutton_change_save_to, 'enable', 'on');
            set(obj.handles.edit_file_prefix, 'enable', 'on');
            set(obj.handles.edit_file_suffix, 'enable', 'on');
            set(obj.handles.edit_file_index, 'enable', 'on');
            set(obj.handles.checkbox_enable_save, 'enable', 'on');
        end
        
        
        function save_to_updated(obj, ~, ~)
            str = obj.controller.setup.saver.save_to;
            set(obj.handles.edit_save_to, 'string', str);
        end
        
        
        function script_updated(obj)
            [pathname, fname] = fileparts(obj.controller.current_script);
            [pathname, path1] = fileparts(pathname);
            [~, path2] = fileparts(pathname);
            set(obj.handles.edit_script, 'string', fullfile(path2, path1, fname));
        end
        
        
        function prefix_updated(obj, ~, ~)
            str = obj.controller.setup.saver.prefix;
            set(obj.handles.edit_file_prefix, 'string', str);
        end
        
        
        function suffix_updated(obj, ~, ~)
            str = obj.controller.setup.saver.suffix;
            set(obj.handles.edit_file_suffix, 'string', str);
        end
        
        
        function index_updated(obj, ~, ~)
            index = obj.controller.setup.saver.index;
            set(obj.handles.edit_file_index, 'string', index);
        end
        
        
        function reward_duration_updated(obj, ~, ~)
            duration = obj.controller.setup.reward.duration;
            set(obj.handles.edit_reward_duration, 'string', sprintf('%i', duration));
        end
        
        
        function enable_updated(obj, ~, ~)
            enable = obj.controller.setup.saver.enable;
            set(obj.handles.checkbox_enable_save, 'value', enable);
        end
        
        
        function acquiring_updated(obj, ~, ~)
            if obj.controller.setup.acquiring_preview
                set(obj.handles.pushbutton_toggle_acq, 'string', 'STOP');
            else
                set(obj.handles.pushbutton_toggle_acq, 'string', 'PREVIEW');
            end
        end
        
        
        function sound_enabled(obj, ~, ~)
            
            % set the toggle buttons
            set(obj.handles.button_enable_sound, 'value', obj.controller.setup.sound.enabled);
            set(obj.handles.button_disable_sound, 'value', ~obj.controller.setup.sound.enabled);
            
            % of the sound has been disabled, make sure the button says
            % PLAY
            if ~obj.controller.setup.sound.enabled
                set(obj.handles.pushbutton_toggle_sound, 'string', 'PLAY');
            end
        end
        
        
        function delete(obj)
            delete(obj.handles.output);
        end   
    end
end