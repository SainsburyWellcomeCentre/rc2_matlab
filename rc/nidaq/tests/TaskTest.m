classdef TaskTest < handle
    
    properties
        IsContinuous
        NumberOfScans
        Rate
        NotifyWhenDataAvailableExceeds
        Frequency
        IsDone = 1
    end
    
    
    methods
        
        function obj = TaskTest()
            
        end
        
        
        function val = addDigitalChannel(obj, dev_name, channel, dir)
            str = sprintf('adding digital channel on %s on chan %s, %s\n', dev_name, channel{1}, dir);
            fprintf(str);
            val = ChanTest;
        end
        
        function val = addAnalogInputChannel(obj, dev_name, channel, dir)
            str = sprintf('adding analog input channel on %s on chan %i, %s\n', dev_name, channel, dir);
            fprintf(str);
            val = ChanTest;
        end
        
        function val = addAnalogOutputChannel(obj, dev_name, channel, dir)
            str = sprintf('adding analog output channel on %s on chan %i, %s\n', dev_name, channel, dir);
            fprintf(str);
            val = ChanTest;
        end
        
        function val = addCounterOutputChannel(obj, dev_name, channel, dir)
            str = sprintf('adding analog output channel on %s on chan %i, %s\n', dev_name, channel, dir);
            fprintf(str);
            val = ChanTest;
        end
        
        
        function addClockConnection(obj, src, dest, type)
            str = sprintf('adding clock connection from %s to %s, %s\n', src, dest, type);
            fprintf(str)
        end
        
        function queueOutputData(obj, data)
            str = sprintf('queueing output data size = (%i, %i)\n', size(data, 1), size(data, 2));
            fprintf(str)
        end
        
        function startBackground(obj)
            str = sprintf('starting task in background\n');
            fprintf(str)
        end
        
        
        function stop(obj)
            str = sprintf('stopping task\n');
            fprintf(str)
        end
        
        function close(obj)
            fprintf('closing task')
        end
    end
end