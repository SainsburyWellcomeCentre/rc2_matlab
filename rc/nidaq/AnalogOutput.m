classdef AnalogOutput < handle
% AnalogOutput Class for handling analog outputs on the NIDAQ
%
%   AnalogOutput Properties:
%       enabled         - whether to use this module
%       task            - handle to the AI session object
%       channel_names   - names of the AI channels
%       channel_ids     - IDs of the AI channels
%       chan            - cell array with the handle to the channel objects
%       idle_offset     - offsets to apply on the analog outputs in an idle state
%       max_voltage     - maximum absolute voltage to apply on the analog outputs
%
%   AnalogOutput Methods:
%       delete          - destructor, deletes the task
%       set_to_idle     - set the analog outputs to their idle state
%       write           - write data to the analog outputs (doesn't output)
%       start           - starts the AI task in the background
%       stop            - stop the AI task
%       close           - delete the AI task
%
%   See also: NI

    properties
        
        enabled
        idle_offset
    end
    
    properties (SetAccess = private)
        
        task
        channel_names = {}
        channel_ids = {}
        chan = {}
        
        max_voltage = 3.3;
    end
    
    
    
    methods
        
        function obj = AnalogOutput(config)
        % AnalogOutput
        %
        %   AnalogOutput(CONFIG) creates the analog output task with
        %   the details described in CONFIG (the main configuration
        %   structure with `ao` field.
        %
        %   See README for details on the configuration.
        
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
        %%delete Destructor, deletes the task
        
            if ~obj.enabled, return, end
            
            obj.close()
        end
        
        
        
        function set_to_idle(obj)
        %%set_to_idle Set the analog outputs to their idle state
        %
        %   set_to_idle() sets the analog outputs to whatever value is in
        %   `idle_offset` property
        %
        %   TODO: check that voltage is not > max_voltage
        
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
        %%write Write data to the analog outputs (doesn't output)
        %
        %   write(DATA) queues the data in DATA to the analog outputs. DATA
        %   should be a # samples x # AO channels matrix with values in
        %   volts to output on the analog outputs. If any data is >
        %   `max_voltage` or < -`max_voltage` it is clipped.
        
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
        %%start Starts the AO task in the background
        %
        %   start()
        
            if ~obj.enabled, return, end
            
            obj.task.startBackground();
        end
        
        
        
        function stop(obj)
        %%stop Stop the AO task
        %
        %   stop()
        
            if ~obj.enabled, return, end
            
            if isvalid(obj.task)
                obj.task.stop()
            end
        end
        
        
        
        function close(obj)
        %%close Delete the AO task
        %
        %   close()
        
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
