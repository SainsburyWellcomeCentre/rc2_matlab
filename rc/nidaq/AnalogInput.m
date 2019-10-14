classdef AnalogInput < handle
    
    properties
        task
        channel_names
        chan = {}
        h_listener
        log_every
    end
    
    
    methods
        function obj = AnalogInput(config)
            obj.task = daq.createSession('ni');
            for i = 1:length(config.nidaq.ai.channel_names)
                obj.channel_names{i} = config.nidaq.ai.channel_names{i};
                obj.chan{i} = addAnalogInputChannel(obj.task, config.nidaq.ai.dev, config.nidaq.ai.channel_id(i), 'Voltage');
            end
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
            obj.log_every = config.nidaq.log_every;
            obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
        end
        
        
        function delete(obj)
            obj.close()
        end
        
        
        function prepare(obj, h_callback)
            obj.task.NotifyWhenDataAvailableExceeds = obj.log_every;
            obj.h_listener = addlistener(obj.task, 'DataAvailable', h_callback);
        end
        
        
        function start(obj)
            obj.task.startBackground();
        end
        
        function stop(obj)
            if isvalid(obj.task)
                stop(obj.task)
                % remove the callback function
                obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
            end
        end
        
        function close(obj)
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
    end
end