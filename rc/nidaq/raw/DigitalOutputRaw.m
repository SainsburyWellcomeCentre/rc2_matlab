classdef DigitalOutputRaw < handle
    % DigitalOutputRaw class for handling digital outputs on the NIDAQ.

    properties
        task_handle % Handle to the daq.ni.NIDAQmx.DAQmxCreateTask object.
        ai_task % Handle to the :class:`AnalogInput` task which is used to run the digital output task.
        rate % Used to configure task rate.
        n_chan % The number of DO channels.
        channel_names = {} % Names of the DO channels.
        channel_ids {} % IDs of the DO channels.
        state % # channels x 1 vector indicating the state of each digital output.
        clock_src % The terminal determining the timebase.
    end
    
    
    properties (SetAccess = private)    
        is_running = false; % Whether the DO task is running.
    end
    
    
    methods
        function obj = DigitalOutputRaw(config, ai_task)
            % Constructor for a :class:`rc.nidaq.raw.DigitalOutputRaw` task
            %
            % DigitialOutputRaw(config, ai_task) creates the digital output task
            % with details described in the main configuration structure with
            % 'do' field.
            %
            % :param ai_task: The handle to the analog input task which is used to trigger and time the digital output tasks.
        
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
            % Destructor for :class:`rc.nidaq.raw.DigitalOutputRaw` task
        
            obj.close()
        end
        
        
        function data = get_toggle(obj, chan, direction)
            % Get data to write to the digitial output lines in order to toggle the state of a given channel.
            %
            % :param chan: The index of the channel to toggle, integer between 1 and :attr:`n_chan`.
            % :param direction: A boolean specifying whether to send the channel high (true) or low (false).
            % :return: A 2 x :attr:`n_chan` matrix containing data to write to the digitial output lines.
        
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
            % Get data to write to the digital output lines in order to pulse the state of a given channel.
            %
            % :param chan: The index of the channel to pulse, integer between 1 and :attr:`n_chan`.
            % :param dur: A value in milliseconds determining the duration of the pulse.
            % :return: A # samples x :attr:`n_chan` matrix containing data to write to the digital output lines.
        
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
            % Start the DO task with write data. If the analog input task is not already running, it is started.
            %
            % :param data: Data to write to the digital output lines before starting the task. Should be in the format of a matrix of # samples x :attr:`n_chan` containing 0/1 values corresponmding to desired states of the digital lines.  
        
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
            % Stop the task.
        
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
            obj.is_running = false;
        end
        
        
        function close(obj)
            % Clear the task.
        
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear do task\n')
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
