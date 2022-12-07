classdef DataTransform < handle
    % DataTransform class for transforming incoming data on the analog
    % inputs into a sensible unit.
    %
    %   DataTransform Properties:
    %       offset         - offset to subtract on each channel
    %       scale          - scale to apply to each channel after offset subtraction
    %
    %   DataTransform Methods:
    %       transform       - perform offset subtraction and scaling

    properties
        offset % Offset to subtract on each channel. 1 x n vector to apply to each channel in n channels.
        scale % Scale to apply to each channel after offset subtraction. 1 x n vector to apply to each channel in n channels.
    end
    
    
    methods
        
        function obj = DataTransform(config)
            % Constructor for a :class:`rc.aux_.DataTransform` transformer.
            % Stores information for and performs a transformation of voltage
            % signals coming into the NIDAQ to useful scales (e.g. V to cm/s).
            %
            % :param config: The main configuration structure.
        
            obj.offset = config.nidaq.ai.offset;
            obj.scale = config.nidaq.ai.scale;
        end
        
        
        function data = transform(obj, data)
            % Transform the data according to an offset and scale.
            %
            % :param data: The raw input data.
            % :return: The transformed data with :attr:`offset` subtracted then multiplied by :attr:`scale`.
        
            data = bsxfun(@minus, data, obj.offset);
            data = bsxfun(@times, data, obj.scale);
        end
    end
end