classdef rc2View < hgsetget
    
    properties
        
        controller
        gui
        handles
    end
    
    
    
    methods
        
        function obj = rc2View(controller)
            
            obj.controller = controller;
            obj.gui = rc2GUI(obj.controller);
            obj.handles = guidata(obj.gui);
            
            start_pos = obj.controller.setup.config.stage.start_pos;
            set(obj.handles.edit_move_to, 'string', sprintf('%.1f', start_pos));
            
            save_to = obj.controller.setup.saver.save_to;
            prefix = obj.controller.setup.saver.prefix;
            suffix = obj.controller.setup.saver.suffix;
            index = obj.controller.setup.saver.index;
            
            set(obj.handles.edit_save_to, 'string', save_to);
            set(obj.handles.edit_file_prefix, 'string', prefix);
            set(obj.handles.edit_file_suffix, 'string', suffix);
            set(obj.handles.edit_file_index, 'string', index);
            
            addlistener(obj.controller.setup.saver, 'index', 'PostSet', @(src, evnt)obj.index_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'enable', 'PostSet', @(src, evnt)obj.enable_updated(src, evnt));
        end
        
        
        function index_updated(obj, ~, ~)
            index = obj.controller.setup.saver.index;
            set(obj.handles.edit_file_index, 'string', index);
        end
        
        
        function enable_updated(obj, ~, ~)
            enable = obj.controller.setup.saver.enable;
            set(obj.handles.checkbox_enable_save, 'value', enable);
        end
        
        
        function delete(obj)
            delete(obj.handles.output);
        end   
    end
end