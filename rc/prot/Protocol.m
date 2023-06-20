classdef Shelter < handle
    
    properties
        
    end
    
    methods
        
        function obj = Protocol()
        end
        
        methods (Abstract)
            run(obj)
        end
    end
end