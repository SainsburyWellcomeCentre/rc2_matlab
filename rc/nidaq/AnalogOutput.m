classdef AnalogOutput < handle
    
    properties
        enabled
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
            
            obj.enabled = config.nidaq.ao.enable;
            if ~obj.enabled
                obj.task.Rate = nan;
                return
            end
            
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
            if ~obj.enabled, return, end
            obj.close()
        end
        
        
        function set_to_idle(obj)
            
            if ~obj.enabled, return, end
            
            % Stop any running tasks first
            obj.stop();
            
            % assert that idle_offset is correct size
            assert(length(obj.idle_offset) == length(obj.chan));
            
            % write initial voltage to AO
            obj.task.outputSingleScan(obj.idle_offset);
            
            fprintf('Voltage output on NI:\n');
            for i = 1 : length(obj.idle_offset)
                fprintf('Channel ID %s: %.7fV\n', obj.channel_ids{i}, obj.idle_offset(i));
            end
        end
        
        
        function write(obj, data)
            
            if ~obj.enabled, return, end
            
            % to avoid DANGER, clip voltage at limits!!
            data(data > obj.max_voltage) = obj.max_voltage;
            data(data < -obj.max_voltage) = -obj.max_voltage;
            
            % assert that the data is correct size
            assert(size(data, 2) == length(obj.chan));
            
            % Queue the output data
            obj.task.queueOutputData(data);
        end
        
        
        function start(obj)
            if ~obj.enabled, return, end
            obj.task.startBackground();
        end
        
        
        function stop(obj)
            if ~obj.enabled, return, end
            if isvalid(obj.task)
                obj.task.stop()
            end
        end
        
        
        function close(obj)
            if ~obj.enabled, return, end
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
        
        
        function val = is_running(obj)
            if ~obj.enabled
                val = false;
                return
            end
            val = obj.task.IsRunning;
        end
        
        
        function val = rate(obj)
            if ~obj.enabled, return, end
            val = obj.task.Rate;
        end
    end
end