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
            addlistener(obj.controller.setup, 'acquiring', 'PostSet', @(src, evnt)obj.acquiring_updated(src, evnt));
            addlistener(obj.controller.setup.reward, 'duration', 'PostSet', @(src, evnt)obj.reward_duration_updated(src, evnt));
        end
        
        
        function save_to_updated(obj, ~, ~)
            str = obj.controller.setup.saver.save_to;
            set(obj.handles.edit_save_to, 'string', str);
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
            is_acquiring = obj.controller.setup.acquiring;
            if is_acquiring
                set(obj.handles.pushbutton_toggle_acq, 'string', 'STOP');
            else
                set(obj.handles.pushbutton_toggle_acq, 'string', 'ACQUIRE');
            end
        end
        
        
        function delete(obj)
            delete(obj.handles.output);
        end   
    end
end