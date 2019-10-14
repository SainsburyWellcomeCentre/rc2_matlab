classdef AnalogOutput < handle
    
    properties
        task
        chan = {}
        channel_names
    end
    
    
    methods
        
        function obj = AnalogOutput(config)
            obj.task = daq.createSession('ni');
            for i = 1:length(config.nidaq.ao.channel_names)
                obj.channel_names = config.nidaq.ao.channel_names{i};
                obj.chan{i} = addAnalogOutputChannel(obj.task, config.nidaq.ao.dev, config.nidaq.ao.channel_id(i), 'Voltage');
            end
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 0;
        end
        
        
        function delete(obj)
            obj.close()
        end
        
        
        function write(obj, data)
            %obj.task.NumberOfScans = size(data, 1);
            obj.task.queueOutputData(data);
        end
        
        
        function start(obj)
            obj.task.startBackground();
        end
        
        
        function stop(obj)
            if isvalid(obj.task)
                obj.task.stop()
            end
        end
        
        
        function close(obj)
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
    end
end