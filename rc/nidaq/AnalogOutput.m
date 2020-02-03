classdef AnalogOutput < handle
    
    properties
        
        task
        channel_names = {}
        channel_ids = {}
        chan = {}
        
        idle_offset
        
        max_voltage = 3.3;
    end
    
    
    methods
        
        function obj = AnalogOutput(config)
        %%obj = AnalogOutput(config)
        %   Handles analog output.
        %       The property "ai_ao_error" is added to all data
        %       But it may be more sensible to move this somewhere else
        
            obj.task = daq.createSession('ni');
            for i = 1:length(config.nidaq.ao.channel_names)
                obj.channel_names{i} = config.nidaq.ao.channel_names{i};
                obj.channel_ids{i} = sprintf('ao%i', config.nidaq.ao.channel_id(i));
                obj.chan{i} = addAnalogOutputChannel(obj.task, config.nidaq.ao.dev, config.nidaq.ao.channel_id(i), 'Voltage');
            end
            
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 0;
            obj.idle_offset = config.nidaq.ao.idle_offset;
            
            % make sure the idle offset provided is not above max_voltage
            if abs(obj.idle_offset) > obj.max_voltage
                obj.idle_offset = 0;
                return
            end
            
            obj.set_to_idle();
        end
        
        
        function delete(obj)
            obj.close()
        end
        
        
        function set_to_idle(obj, offset)
            
            % By default don't apply an offset
            VariableDefault('offset', 0);
            
            % Stop any running tasks first
            obj.stop();
            
            % write initial voltage to AO
            obj.task.outputSingleScan(obj.idle_offset + offset);
        end
        
        
        function write(obj, data, offset)
            
            % By default don't apply an offset
            VariableDefault('offset', 0);
            
            % to avoid DANGER, clip voltage at limits!!
            data(data > obj.max_voltage) = obj.max_voltage;
            data(data < -obj.max_voltage) = -obj.max_voltage;
            
            % Queue the output data
            obj.task.queueOutputData(data + offset);
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