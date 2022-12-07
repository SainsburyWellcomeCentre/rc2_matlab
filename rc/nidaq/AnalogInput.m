classdef AnalogInput < handle
    % AnalogInput class for handling analog inputs on the NIDAQ.

    properties
        enabled % Boolean specifying whether the module is used.
    end
        
    properties (SetAccess = private)
        task % The AI `session object <https://uk.mathworks.com/help/daq/daq.interfaces.dataacquisition.daq.html>`_.
        channel_names = {} % Names of the AI channels.
        channel_ids = {} % IDs of the AI channels.
        chan = {} % Cell array with the handle to the channel objects.
        h_listener % Handle to the listener containing the `callback function <https://uk.mathworks.com/help/matlab/ref/handle.addlistener.html>`_
        log_every % Number of samples between calling the callback function.
    end
    

    methods
        function obj = AnalogInput(config)
            % Constructor for a :mod:`rc.nidaq` :class:`AnalogInput` task.
            % AnalogInput(config) creates the analog input task with details
            % described in the main configuration structure with `ai` field.
            %
            % :param config: The main configuration structure.
        
            obj.enabled = config.nidaq.ai.enable;
            
            if ~obj.enabled
                % fill in some blank information
                obj.task.Rate = nan;
                return
            end
            
            obj.task = daq.createSession('ni');
            
            for i = 1:length(config.nidaq.ai.channel_names)
                
                obj.channel_names{i} = config.nidaq.ai.channel_names{i};
                obj.channel_ids{i} = sprintf('ai%i', config.nidaq.ai.channel_id(i));
                obj.chan{i} = addAnalogInputChannel(obj.task, config.nidaq.ai.dev, config.nidaq.ai.channel_id(i), 'Voltage');
            end
            
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
            obj.log_every = config.nidaq.log_every;
            obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
        end
        
        
        function delete(obj)
            % Destructor for :mod:`rc.nidaq` :class:`AnalogInput` task.
        
            obj.close()
        end
        
        
        function prepare(obj, h_callback)
            % Prepare the analog input for acquisition.
            %
            % :param h_callback: function callback invoked by analog input task. Should be a valid function that can be passed to `addlistener(hSource, EventName, callback) <https://uk.mathworks.com/help/matlab/ref/handle.addlistener.html>`_.
        
            if ~obj.enabled, return, end
            
            obj.task.NotifyWhenDataAvailableExceeds = obj.log_every;
            delete(obj.h_listener);
            obj.h_listener = addlistener(obj.task, 'DataAvailable', h_callback);
        end
        
        
        
        function start(obj)
            % Starts the analog input task in the background.
        
            if ~obj.enabled, return, end
            
            obj.task.startBackground();
        end
        
        
        
        function stop(obj)
            % Stops the analog input task.
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                stop(obj.task)
                % remove the callback function.
                delete(obj.h_listener);
                obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
            end
        end
        
        
        
        function close(obj)
            % Deletes the analog input task.
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
        
        
        
        function val = rate(obj)
            if ~obj.enabled, val = nan; return, end
            val = obj.task.Rate;
        end
    end
end
