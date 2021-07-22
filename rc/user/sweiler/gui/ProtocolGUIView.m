classdef ProtocolGUIView < handle
    
    properties
        
        controller
        gui
    end
    
    
    methods
        
        function obj = ProtocolGUIView(controller)
            
            obj.controller = controller;
            obj.gui = ProtocolGUI(obj.controller);
        end
        
        
        function delete(obj)
            if isvalid(obj.gui)
                if isvalid(obj.gui.UIFigure)
                    close(obj.gui.UIFigure);
                end
                delete(obj.gui);
            end
        end
    end
end
