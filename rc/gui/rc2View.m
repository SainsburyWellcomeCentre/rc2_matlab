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
        end
        
        
        
        function delete(obj)
            delete(obj.handles.output);
        end   
    end
end