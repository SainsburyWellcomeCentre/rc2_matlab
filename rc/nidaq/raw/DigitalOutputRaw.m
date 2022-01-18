classdef DigitalOutputRaw < handle
% DigitalOutputRaw Class for handling digital outputs on the NIDAQ
%
%   DigitalOutputRaw Properties:
%       enabled         - whether to use this module
%       task_handle     - handle to the daq.ni.NIDAQmx.DAQmxCreateTask object
%       ai_task         - handle to the AI task which is used to run the DO task
%       n_chan          - number of DO channels
%       channel_names   - names of the DO channels
%       channel_ids     - IDs of the DO channels
%       state           - # channels x 1 vector indicating the state of each digital output
%       clock_src       - the terminal determining the timebase
%       is_running      - whether the DO task is running
%
%   DigitalOutputRaw Methods:
%       delete          - destructor, clears the task
%       get_toggle      - return data for toggling the state of the digital oututs
%       get_pulse       - return data for pulsing one of the digital output channels
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
        ai_task
        
        rate
        
        n_chan
        
        channel_names = {}
        channel_ids = {}
        state
        clock_src = ''
        
        is_running = false;
    end
    
    
    
    methods
        
        function obj = DigitalOutputRaw(config, ai_task)  
        % DigitalOutputRaw
        %
        %   DigitalOutputRaw(CONFIG, AI_TASK) creates the digital output
        %   task with details described in CONFIG (the main configuration
        %   structure with `do` field. Also takes AI_TASK, the handle to
        %   the analog input task which is used to trigger and time the
        %   digital output tasks.
        %
        %   See README for details on the configuration.
            
            obj.enabled = config.nidaq.do.enable;
            if ~obj.enabled, return, end
            
            obj.ai_task = ai_task;
            
            obj.clock_src = config.nidaq.do.clock_src;
            obj.rate = obj.ai_task.Rate;
            
            [status, obj.task_handle] = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), uint64(0));
            obj.handle_fault(status, 'DAQmxCreateTask');
            
            obj.n_chan = length(config.nidaq.do.channel_names);
            
            for i = 1 : obj.n_chan
                
                obj.channel_names{i} = config.nidaq.do.channel_names{i};
                obj.channel_ids{i} = config.nidaq.do.channel_id{i};
                dev_str = sprintf('%s/%s', config.nidaq.do.dev, config.nidaq.do.channel_id{i});
                status = daq.ni.NIDAQmx.DAQmxCreateDOChan(obj.task_handle, dev_str, char(0), daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines);
                obj.handle_fault(status, 'DAQmxCreateDOChan');
                obj.state(i) = false;
            end
            
            status = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(obj.task_handle, obj.clock_src, double(obj.rate), ...
                daq.ni.NIDAQmx.DAQmx_Val_Rising, daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps, uint64(1000));
            obj.handle_fault(status, 'DAQmxCfgSampClkTiming');
%              status = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig(obj.task_handle, '/Dev2/PFI0', daq.ni.NIDAQmx.DAQmx_Val_Rising);
%              obj.handle_fault(status, 'DAQmxCfgDigEdgeStartTrig');
            
            %%WRITE HERE
            obj.start(repmat(obj.state, 2, 1));
        end
        
        
        
        function delete(obj)
        %%delete Destructor, clears the task
        
            if ~obj.enabled, return, end
            obj.close()
        end
        
        
        
        function data = get_toggle(obj, chan, direction)
        %%get_toggle Return data for toggling the state of the digital
        %%oututs
        %
        %   DATA = get_toggle(CHANNEL_IDX, DIRECTION) returns data to write to the
        %   digital output lines in order to toggle the state of CHANNEL_ID.
        %   The CHANNEL_ID should be an integer from 1 to # DO channels,
        %   and DIRECTION should be a boolean, true or false, determining
        %   whether to send the channel high or low.
        %
        %   A 2 x # DO channels boolean matrix is returned in DATA to write
        %   to the digital output lines.
        %
        %   See also: start
        
            if ~obj.enabled, return, end
            
            toggle_length = 2;
            data = nan(toggle_length, obj.n_chan);
            
            for i = 1 : obj.n_chan
                if i ~= chan
                    data(:, i) = obj.state(i);
                else
                    data(:, i) = direction;
                end
            end
        end
        
        
        
        function data = get_pulse(obj, chan, dur)
        %%get_pulse Return data for pulsing one of the digital output
        %%channels
        %
        %   DATA = get_pulse(CHANNEL_ID, DURATION) returns data to write to the
        %   digital output lines in order to send a digital pulse on CHANNEL_ID.
        %   The CHANNEL_ID should be an integer from 1 to # DO channels,
        %   and DURATION is a value, in milliseconds, determining the
        %   duration of the pulse.
        %
        %   A # samples x # DO channels boolean matrix is returned in DATA
        %   to write to the digital output lines.
        %
        %   See also: start
        
            if ~obj.enabled, return, end
            
            n_samples = round(obj.rate*dur*1e-3);
            data = nan(n_samples, obj.n_chan);
            for i = 1 : obj.n_chan
                if obj.state(i)
                    data(:, i) = 1;
                elseif ~obj.state(i) && i ~= chan
                    data(:, i) = 0;
                else
                    data(:, i) = 1;
                    data(end, i) = 0;
                end
            end
        end
        
        
        
        function start(obj, data)
        %%start Start the DO task
        %
        %   start(DATA) writes the data in DATA to the digital output
        %   lines, and starts the digital output task. If the analog input
        %   task is not running, it is started. DATA should be a # samples
        %   x # DO channels matrix of zeros and ones determining the output
        %   on the digital lines.
        %
        %   See also: get_toggle, get_duration
        
            if ~obj.enabled, return, end
            
            if obj.is_running
                fprintf('not running digital output\n');
                return
            end
            
            n_samples = size(data, 1);
            status = daq.ni.NIDAQmx.DAQmxSetSampQuantSampPerChan(obj.task_handle, uint64(n_samples));
            obj.handle_fault(status, 'DAQmxSetSampQuantSampPerChan');
            
            [status, ~, ~] = daq.ni.NIDAQmx.DAQmxWriteDigitalLines( ...
                        obj.task_handle, ...
                        int32(n_samples), ...
                        uint32(false), ...
                        double(10), ...
                        uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel), ...
                        uint8(data(:)), ...
                        int32(0), ...
                        uint32(0));
            obj.handle_fault(status, 'DAQmxWriteDigitalLines');
            
            obj.is_running = true;
            
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            obj.handle_fault(status, 'start');
            
            ai_task_off = ~obj.ai_task.IsRunning;
            
            if ai_task_off
                obj.ai_task.IsContinuous = 0;
                obj.ai_task.NumberOfScans = n_samples + 10;
                obj.ai_task.startBackground()
                wait(obj.ai_task)
                obj.ai_task.stop()
                obj.ai_task.IsContinuous = 1;
            end
            
            status = daq.ni.NIDAQmx.DAQmxWaitUntilTaskDone(obj.task_handle, double(10));
            obj.handle_fault(status, 'DAQmxWaitUntilTaskDone')
            
            obj.stop();
            
            obj.state = data(end, :);
        end
        
        
        
        function stop(obj)
        %%stop Stop the task
        %
        %   stop() stops the take with DAQmxStopTask
        
            if ~obj.enabled, return, end
            
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
            obj.is_running = false;
        end
        
        
        
        function close(obj)
        %%close Clear the task
        %
        %   close() calls daq.ni.NIDAQmx.DAQmxClearTask
        
            if ~obj.enabled, return, end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear do task\n')
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
