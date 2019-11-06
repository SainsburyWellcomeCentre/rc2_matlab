classdef DataTransform < handle
    
    properties
        
        offset
        scale
    end
    
    
    methods
        
        function obj = DataTransform(config)
            
            obj.offset = config.nidaq.ai.offset;
            obj.scale = config.nidaq.ai.scale;
        end
        
        
        function data = transform(obj, data)
            
            data = bsxfun(@minus, data, obj.offset);
            data = bsxfun(@times, data, obj.scale);
        end
    end
end