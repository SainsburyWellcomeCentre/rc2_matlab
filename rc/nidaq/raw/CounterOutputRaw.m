classdef CounterOutputRaw < handle
    
    properties
        task_handle
        channel_names
    end
    
    
    methods
        
        function obj = CounterOutputRaw(config)
            
            init_delay = 0;
            low_samps = 233;
            high_samps = 100;
            
            [status, obj.task_handle] = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), uint64(0));
            obj.handle_fault(status);
            
            for i = 1:length(config.nidaq.co.channel_names)
                obj.channel_names{i} = config.nidaq.co.channel_names{i};
                dev_str = sprintf('%s/ctr%i', config.nidaq.co.dev, config.nidaq.co.channel_id(i));
                status = daq.ni.NIDAQmx.DAQmxCreateCOPulseChanTicks(obj.task_handle, dev_str, char(0), '/Dev2/ai/SampleClock', ...
                    daq.ni.NIDAQmx.DAQmx_Val_Low, int32(init_delay), int32(low_samps), int32(high_samps));
                obj.handle_fault(status);
            end
            
            status = daq.ni.NIDAQmx.DAQmxCfgImplicitTiming(obj.task_handle, daq.ni.NIDAQmx.DAQmx_Val_ContSamps, uint64(1000));
            obj.handle_fault(status);
        end
        
        function delete(obj)
            obj.close();
        end
        
        function start(obj)
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            obj.handle_fault(status);
        end
        
        function stop(obj)
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status);
        end
        
        function close(obj)
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear co task')
            end
        end
        
        function handle_fault(obj, status)
            if status ~= 0
                obj.close()
            end
        end
    end
end