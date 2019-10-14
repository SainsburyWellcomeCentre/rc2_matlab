classdef CounterOutputRaw < handle
    
    
    
    properties
        task_handle
        channel_names
    end
    
    methods
        
        function obj = CounterOutput(config)
            
            init_delay = 0;
            low_samps = 233;
            high_samps = 100;
            
            obj.task_handle = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), uint64(0));
            
            for i = 1:length(config.nidaq.co.channel_names)
                obj.channel_names{i} = config.nidaq.co.channel_names{i};
                dev_str = sprintf('%s/ctr%i', config.nidaq.co.dev, config.nidaq.co.channel_id(i));
                daq.ni.NIDAQmx.DAQmxCreateCOPulseChanTicks(obj.task_handle, dev_str, '', '/Dev2/ai/SampleClock', ...
                    daq.ni.NIDAQmx.DAQmx_Val_Low, int32(init_delay), int32(low_samps), int32(high_samps));
            end
            
            daq.ni.NIDAQmx.DAQmxCfgImplicitTiming(obj.task_handle, daq.ni.NIDAQmx.DAQmx_Val_ContSamps, uint64(1000));
        end
        
        
        function start(obj)
            daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
        end
        
        function stop(obj)
            daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
        end
        
        function close(obj)
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
        end
    end
end