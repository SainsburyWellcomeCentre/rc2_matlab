classdef AnalogInput < handle
    
    properties
        enabled
        task
        channel_names = {}
        channel_ids = {}
        chan = {}
        h_listener
        log_every
    end
    
    
    methods
        function obj = AnalogInput(config)
            
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
            obj.close()
        end
        
        
        function prepare(obj, h_callback)
            if ~obj.enabled, return, end
            obj.task.NotifyWhenDataAvailableExceeds = obj.log_every;
            delete(obj.h_listener);
            obj.h_listener = addlistener(obj.task, 'DataAvailable', h_callback);
        end
        
        
        function start(obj)
            if ~obj.enabled, return, end
            obj.task.startBackground();
        end
        
        
        function stop(obj)
            
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                stop(obj.task)
                % remove the callback function
                delete(obj.h_listener);
                obj.h_listener = addlistener(obj.task, 'DataAvailable', @(x, y)pass(x, y));
            end
        end
        
        
        function close(obj)
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