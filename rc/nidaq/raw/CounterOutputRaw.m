classdef CounterOutputRaw < handle
    % CounterOutputRaw Class for handling counter outputs on the NIDAQ. 

    properties
        task_handle % Handle to the daq.ni.NIDAQmx.DAQmxCreateTask object.
        channel_names = {} % Names of the CO channels.
        channel_ids = {} % IDs of the CO channels.
    end
    
    properties (SetAccess = private)
        init_delay % The number of timebase ticks to wait before generating the first pulse.
        low_samps % The number of timebase ticks that the pulse is low.
        high_samps % The number of timebase ticks that the pulse is high.
        clock_src % The terminal deciding the timebase.
    end
    
    
    methods
        
        function obj = CounterOutputRaw(config)
            % Constructor for a :class:`rc.nidaq.raw.CounterOutputRaw` task.
            %
            % CounterOutputRaw(config) creates the counter counter output task
            % with the details described in the main configuration structure with the `co` field.
        
            obj.init_delay = config.nidaq.co.init_delay;
            obj.low_samps = config.nidaq.co.pulse_dur - config.nidaq.co.pulse_high;
            obj.high_samps = config.nidaq.co.pulse_high;
            obj.clock_src = config.nidaq.co.clock_src;
            
            [status, obj.task_handle] = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), uint64(0));
            obj.handle_fault(status, 'DAQmxCreateTask');
            
            for i = 1:length(config.nidaq.co.channel_names)
                
                obj.channel_names{i} = config.nidaq.co.channel_names{i};
                obj.channel_ids{i} = sprintf('ctr%i', config.nidaq.co.channel_id(i));
                dev_str = sprintf('%s/ctr%i', config.nidaq.co.dev, config.nidaq.co.channel_id(i));
                status = daq.ni.NIDAQmx.DAQmxCreateCOPulseChanTicks(obj.task_handle, dev_str, char(0), obj.clock_src, ...
                    daq.ni.NIDAQmx.DAQmx_Val_Low, int32(obj.init_delay), int32(obj.low_samps), int32(obj.high_samps));
                obj.handle_fault(status, 'DAQmxCreateCOPulseChanTicks');
            end
            
            status = daq.ni.NIDAQmx.DAQmxCfgImplicitTiming(obj.task_handle, daq.ni.NIDAQmx.DAQmx_Val_ContSamps, uint64(1000));
            obj.handle_fault(status, 'DAQmxCfgImplicitTiming');
        end
        
        
        function delete(obj)
            % Destructor for :class:`rc.nidaq.raw.CounterOutputRaw` task.

            obj.close();
        end
        
        function start(obj)
            % Start the task.
            
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStartTask');
        end
        
        
        function stop(obj)
            % Stop the task.
        
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
        end
        
        
        function close(obj)
            % Clear the task.
        
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear co task\n')
            end
        end
        
        
        function handle_fault(obj, status, loc)
            % Handle faults in the task and then clear the task. NOTE AE - This should be private inernal method.
            %
            % :param status: The task status, will print a message for status values that are not 0.
            % :param loc: A string representing the source of the error.
        
            if status ~= 0
                fprintf('%s: error: %i, %s\n', class(obj), status, loc);
                obj.close()
            end
        end
    end
end
