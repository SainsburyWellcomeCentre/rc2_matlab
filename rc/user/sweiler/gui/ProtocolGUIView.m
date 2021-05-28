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
    end
end
