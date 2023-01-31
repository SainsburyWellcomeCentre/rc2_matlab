classdef GoNogo_DoubleRotation_GUIView < handle
    
    properties
        
        controller
        gui
    end
    
    
    methods
        
        function obj = GoNogo_DoubleRotation_GUIView(controller)
            
            obj.controller = controller;
            obj.gui = GoNogo_DoubleRotation_GUI(obj.controller);  % 打开MATLAB APP文件GoNogo_DoubleRotation_GUI.mlapp（RC2界面）。参数controller为ProtocolSequence类变量（GoNogo_DoubleRotation_GUIController类变量）。
            
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
