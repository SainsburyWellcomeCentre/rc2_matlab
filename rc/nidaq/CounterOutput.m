classdef CounterOutput < handle
    
    properties
        task
        chan = {}
        channel_names
    end
    
    methods
        
        function obj = CounterOutput(config)
            obj.task = daq.createSession('ni');
            for i = 1:length(config.nidaq.co.channel_names)
                obj.channel_names{i} = config.nidaq.co.channel_names{i};
                obj.chan{i} = addCounterOutputChannel(obj.task, config.nidaq.co.dev, config.nidaq.co.channel_id(i), 'PulseGeneration');
                obj.chan{i}.Frequency = config.nidaq.co.freq(i);
            end
            
            %obj.task.addClockConnection('/Dev2/ai/SampleClock', '/Dev2/co/SampleClock', 'ScanClock');
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
        end
        
        function start(obj)
            obj.task.startBackground();
        end
        
        function stop(obj)
            if isvalid(obj.task)
                stop(obj.task)
            end
        end
        
        function close(obj)
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
    end
end