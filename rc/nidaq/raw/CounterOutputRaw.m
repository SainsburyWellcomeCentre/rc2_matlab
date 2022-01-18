classdef CounterOutputRaw < handle
% CounterOutputRaw Class for handling counter outputs on the NIDAQ
%
%   CounterOutputRaw Properties:
%       enabled         - whether to use this module
%       task_handle     - handle to the daq.ni.NIDAQmx.DAQmxCreateTask object
%       channel_names   - names of the CO channels
%       channel_ids     - IDs of the CO channels
%       init_delay      - the number of timebase ticks to wait before generating the first pulse
%       low_samps       - the number of timebase ticks that the pulse is low
%       high_samps      - the number of timebase ticks that the pulse is high
%       clock_src       - the terminal determining the timebase
%
%   CounterOutputRaw Methods:
%       delete          - destructor, clears the task
%       start           - start the task
%       stop            - stop the task
%       close           - clear the task
%       handle_fault    - handles faults and prints error message
%
%   See also: NI
%   See also
%   https://zone.ni.com/reference/en-XX/help/370471AM-01/TOC3.htm
%   for description of underlying C functions

    properties

        enabled
    end
    
    properties (SetAccess = private)

        task_handle
        channel_names = {}
        channel_ids = {}
        
        init_delay = nan
        low_samps = nan
        high_samps = nan
        clock_src = nan
    end
    
    
    
    methods
        
        function obj = CounterOutputRaw(config)
        % CounterOutputRaw
        %
        %   CounterOutputRaw(CONFIG) creates the counter output task with
        %   the details described in CONFIG (the main configuration
        %   structure with `co` field.
        %
        %   See README for details on the configuration.
        
            obj.enabled = config.nidaq.co.enable;
            if ~obj.enabled, return, end
            
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
        %%delete Destructor, clears the task
            
            if ~obj.enabled, return, end
            
            obj.close();
        end
        
        
        
        function start(obj)
        %%start Start the task
        %
        %   start() calls daq.ni.NIDAQmx.DAQmxStartTask
        
            if ~obj.enabled, return, end
            
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStartTask');
        end
        
        
        
        function stop(obj)
        %%stop Stop the task
        %
        %   stop() calls daq.ni.NIDAQmx.DAQmxStopTask
        
            if ~obj.enabled, return, end
            
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
        end
        
        
        
        function close(obj)
        %%close Clear the task
        %
        %   close() calls daq.ni.NIDAQmx.DAQmxClearTask
        
            if ~obj.enabled, return, end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear co task\n')
            end
        end
        
        
        
        function handle_fault(obj, status, loc)
        %%handle_fault Handle faults
        %
        %   handle_fault(STATUS, SRC) prints an message if STATUS is not 0,
        %   identifying the source of the error with the string SRC. The
        %   task is cleared.
        
            if ~obj.enabled, return, end
            
            if status ~= 0
                fprintf('%s: error: %i, %s\n', class(obj), status, loc);
                obj.close()
            end
        end
    end
end
