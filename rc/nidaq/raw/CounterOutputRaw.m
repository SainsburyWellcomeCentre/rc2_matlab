classdef CounterOutputRaw < handle
    
    properties
        task_handle
        channel_names
    end
    
    properties (SetAccess = private)
        init_delay
        low_samps
        high_samps
        clock_src
    end
    
    methods
        
        function obj = CounterOutputRaw(config)
            
            obj.init_delay = config.nidaq.co.init_delay;
            obj.low_samps = config.nidaq.co.pulse_dur - config.nidaq.co.pulse_high;
            obj.high_samps = config.nidaq.co.pulse_high;
            obj.clock_src = config.nidaq.co.clock_src;
            
            [status, obj.task_handle] = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), uint64(0));
            obj.handle_fault(status, 'DAQmxCreateTask');
            
            for i = 1:length(config.nidaq.co.channel_names)
                obj.channel_names{i} = config.nidaq.co.channel_names{i};
                dev_str = sprintf('%s/ctr%i', config.nidaq.co.dev, config.nidaq.co.channel_id(i));
                status = daq.ni.NIDAQmx.DAQmxCreateCOPulseChanTicks(obj.task_handle, dev_str, char(0), obj.clock_src, ...
                    daq.ni.NIDAQmx.DAQmx_Val_Low, int32(obj.init_delay), int32(obj.low_samps), int32(obj.high_samps));
                obj.handle_fault(status, 'DAQmxCreateCOPulseChanTicks');
            end
            
            status = daq.ni.NIDAQmx.DAQmxCfgImplicitTiming(obj.task_handle, daq.ni.NIDAQmx.DAQmx_Val_ContSamps, uint64(1000));
            obj.handle_fault(status, 'DAQmxCfgImplicitTiming');
        end
        
        
        function delete(obj)
            obj.close();
        end
        
        
        function start(obj)
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStartTask');
        end
        
        function stop(obj)
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
        end
        
        function close(obj)
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear co task\n')
            end
        end
        
        function handle_fault(obj, status, loc)
            if status ~= 0
                fprintf('%s: error: %i, %s\n', class(obj), status, loc);
                obj.close()
            end
        end
    end
end