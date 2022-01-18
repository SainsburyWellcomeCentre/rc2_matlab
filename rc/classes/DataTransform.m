classdef DataTransform < handle
% DataTransform Class for transforming the incoming data on the analog
% inputs into a sensible unit.
%
%   DataTransform Properties:
%       offset         - offset to subtract on each channel
%       scale          - scale to apply to each channel after offset subtraction
%
%   DataTransform Methods:
%       transform       - perform offset subtraction and scaling

    properties
        
        offset
        scale
    end
    
    
    
    methods
        
        function obj = DataTransform(config)
        %%obj = DATATRANSFORM(config)
        %   Stores information for and performs a transformation of voltage
        %   signals coming into the NIDAQ to useful scales (e.g. V to cm/s).
        %       offset and scale are 1 x n vectors containing the offset to
        %       subtract and the scale to MULTIPLY by for each of the n
        %       channels in data.
        
            obj.offset = config.nidaq.ai.offset;
            obj.scale = config.nidaq.ai.scale;
        end
        
        
        
        function data = transform(obj, data)
        %%data = TRANSFORM(obj, data)
        %   Transform the data according to an offset and a scale.
        %   Inputs:
        %       data - the "raw" data.
        %   Outputs:
        %       data - data after offset subracted and then scaled (in that
        %       order)
        
            data = bsxfun(@minus, data, obj.offset);
            data = bsxfun(@times, data, obj.scale);
        end
    end
end
