classdef DigitalOutputSimpleRaw < handle
    
    properties
        task_handle
        
        n_chan
        
        channel_names
        channel_ids
        state
    end
    
    
    methods
        
        function obj = DigitalOutputSimpleRaw(config)
            
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
            
            %%WRITE HERE
            obj.start(repmat(obj.state, 2, 1));
        end
        
        
        function delete(obj)
            obj.close()
        end
        
        
        function data = get_toggle(obj, chan, direction)
            
            toggle_length = 1;
            data = nan(toggle_length, obj.n_chan);
            
            for i = 1 : obj.n_chan
                if i ~= chan
                    data(:, i) = obj.state(i);
                else
                    data(:, i) = direction;
                end
            end
        end
        
        
        function start(obj, data)
            
            % TODO: look into on-demand
            
            [status, ~, ~] = daq.ni.NIDAQmx.DAQmxWriteDigitalLines( ...
                        obj.task_handle, ...                                % task handle
                        int32(1), ...                               % number of samples
                        uint32(true), ...                                  % auto start
                        double(10), ...                                     % time out
                        uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel), ...
                        uint8(data(:)), ...
                        int32(0), ...
                        uint32(0));
            obj.handle_fault(status, 'DAQmxWriteDigitalLines');
            
            %status = daq.ni.NIDAQmx.DAQmxStartTask(obj.task_handle);
            %obj.handle_fault(status, 'start');
            
            %status = daq.ni.NIDAQmx.DAQmxWaitUntilTaskDone(obj.task_handle, double(10));
            %obj.handle_fault(status, 'DAQmxWaitUntilTaskDone')
            %obj.stop();
            
            obj.state = data(end, :);
        end
        
        function stop(obj)
            status = daq.ni.NIDAQmx.DAQmxStopTask(obj.task_handle);
            obj.handle_fault(status, 'DAQmxStopTask');
        end
        
        function close(obj)
            status = daq.ni.NIDAQmx.DAQmxClearTask(obj.task_handle);
            if status ~= 0
                fprintf('couldn''t clear do task\n')
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