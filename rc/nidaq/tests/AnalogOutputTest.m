classdef AnalogOutputTest < handle
    
    properties
        task
        chan = {}
        channel_names
    end
    
    
    methods
        
        function obj = AnalogOutputTest(config)
            obj.task = TaskTest();
            for i = 1:length(config.nidaq.ao.channel_names)
                obj.channel_names = config.nidaq.ao.channel_names{i};
                obj.chan{i} = addAnalogOutputChannel(obj.task, config.nidaq.ao.dev, config.nidaq.ao.channel_id(i), 'Voltage');
            end
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 0;
        end
        
        function write(obj, data)
            obj.task.NumberOfScans = size(data, 1);
            obj.task.queueOutputData(data);
        end
        
        function start(obj)
            obj.task.startBackground();
        end
        
        function stop(obj)
            obj.task.stop()
        end
        
        function close(obj)
            obj.task.close()
        end
    end
end