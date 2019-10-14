classdef AnalogInput < handle
    
    properties
        task
        channel_names
        chan
        h_listener
    end
    
    
    methods
        function obj = AnalogInput(config)
            obj.task = daq.createSession('ni');
            for i = 1:length(config.nidaq.ai.channel_names)
                obj.channel_names{i} = config.nidaq.ai.channel_names{i};
                obj.chan(i) = addAnalogInputChannel(obj.task, config.nidaq.ai.dev, config.nidaq.ai.channel_id(i), 'Voltage');
            end
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
        end
        
        
        function prepare(obj, rate, h_callback)
            obj.task.NotifyWhenDataAvailableExceeds = rate;
            obj.h_listener = addlistener(obj.task, 'DataAvailable', h_callback);
        end
        
        
        function start(obj)
            obj.task.startBackground();
        end
        
        function stop(obj)
            stop(obj.task)
        end
        
        function close(obj)
            close(obj.task)
        end
    end
end