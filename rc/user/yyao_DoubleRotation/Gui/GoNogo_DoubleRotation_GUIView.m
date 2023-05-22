classdef GoNogo_DoubleRotation_GUIView < handle
    
    properties
        
        controller
        gui
    end
    
    
    methods
        
        function obj = GoNogo_DoubleRotation_GUIView(controller)
            
            obj.controller = controller;
            obj.gui = GoNogo_DoubleRotation_GUI(obj.controller);  
            
            obj.gui.UIFigure.Position = [1200,70,470,400];
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
