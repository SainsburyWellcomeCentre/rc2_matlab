classdef DigitalInput < handle
    % DigitalInput class for handling digital inputs on the NIDAQ.

    properties
        enabled % Boolean specifying whether the module is used.
    end
    
    properties (SetAccess = private)
        task % The DI `session object <https://uk.mathworks.com/help/daq/daq.interfaces.dataacquisition.daq.html>`_.
        ai_task % Not in use.
        channel_names = {} % Names of the DI channels.
        channel_ids = {} % IDs of the DI channels.
        chan = {} % Cell array with the handle to the channel objects.
        n_chan % number of digital input channels
        state % Not in use.
        ai_chan % Not in use.
    end
    
    
    methods
        
        function obj = DigitalInput(config)
            % Constructor for a :mod:`rc.nidaq` :class:`DigitalInput` task.
            % DigitalInput(config) creates the digital input task with the details
            % described in the main configuration structure with `ai` field.
            %
            % :param config: The main configuration structure.
        
            obj.enabled = config.nidaq.di.enable;
            if ~obj.enabled, return, end
            
            obj.task = daq.createSession('ni');
            
            obj.n_chan = length(config.nidaq.di.channel_names);
            
            for i = 1 : obj.n_chan
                
                obj.channel_names{i} = config.nidaq.di.channel_names{i};
                obj.channel_ids{i} = config.nidaq.di.channel_id{i};
                obj.chan{i} = addDigitalChannel(obj.task, config.nidaq.di.dev, config.nidaq.di.channel_id{i}, 'InputOnly');
            end
            
            obj.task.IsContinuous = 0;
        end
        
        
        function data = read(obj)
            % Read the state of all digital inputs.
            %
            % :return: A data matrix with the state of all digital inputs in a 1 x :attr:`n_chan` boolean array.
        
            if ~obj.enabled, return, end
            
            data = obj.task.inputSingleScan();
        end
        
        
        function data = read_channel(obj, chan)
            % Read the state of a digitial input channel.
            %
            % :param chan: The index of the channel to read between 1 and :attr:`n_chan`.
            % :return: A boolean representing the high/low state of the digital input channel.
        
            if ~obj.enabled, return, end
            
            data = obj.read();
            data = data(chan);
        end
        
        
        function close(obj)
            % Delete the DI task.
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                delete(obj.task);
            end
        end
    end
end
