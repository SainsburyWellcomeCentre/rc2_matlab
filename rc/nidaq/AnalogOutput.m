classdef AnalogOutput < handle
    % AnalogOutput class for handling analog outputs on the NIDAQ.

    properties
        task % The AO `session object <https://uk.mathworks.com/help/daq/daq.interfaces.dataacquisition.daq.html>`_.  
        channel_names = {} % Names of the AO channels.
        channel_ids = {} % IDs of the AO channels.
        chan = {} % Cell array with the handle to the channel objects.
        idle_offset % Offset to apply on the analog inputs in an idle state. 
        max_voltage = 3.3; % Maximum absolute voltage to apply on the analog outputs.
    end
    

    methods
        function obj = AnalogOutput(config)
            % Constructor for a :mod:`rc.nidaq` :class:`AnalogOutput` task
            % AnalogInput(config) creates the analog output task with details
            % described in the main configuration structure with `ai` field.
            %
            % :param config: The main configuration structure
        
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
            % Destructor for :mod:`rc.nidaq` :class:`AnalogOutput` task.
        
            obj.close()
        end
        
        
        function set_to_idle(obj)
            % Sets the analog outputs to the value defined by :attr:`idle_offset`
            %  
            %   TODO: check that voltage is not > :attr:`max_voltage`
        
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
            % Write data to the analog output buffer.
            %
            % :param data: # samples x # AO channels matrix with values in volts. Any data > :attr:`max_voltage` or < -:attr:`max_voltage` is clipped.
        
            % to avoid DANGER, clip voltage at limits!!
            data(data > obj.max_voltage) = obj.max_voltage;
            data(data < -obj.max_voltage) = -obj.max_voltage;
            
            % assert that the data is correct size
            assert(size(data, 2) == length(obj.chan));
            
            % Queue the output data
            obj.task.queueOutputData(data);
        end
        
        
        function start(obj)
            % Starts the analog output task in the background.

            obj.task.startBackground();
        end
        
        
        function stop(obj)
            % Stops the analog output task.
        
            if isvalid(obj.task)
                obj.task.stop()
            end
        end
        
        
        function close(obj)
            % Deletes the analog output task.
        
            if isvalid(obj.task)
                delete(obj.task)
            end
        end
    end
end
