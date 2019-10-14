classdef DigitalOutput < handle
    
    properties
        task
        ai_task
        channel_names
        chan = {}
        n_chan
        state
        ai_chan
    end
    
    
    methods
        
        function obj = DigitalOutput(config, ai_task)
            
            obj.task = daq.createSession('ni');
            obj.ai_task = ai_task;
            obj.n_chan = length(config.nidaq.do.channel_names);
            for i = 1 : obj.n_chan
                obj.channel_names{i} = config.nidaq.do.channel_names{i};
                obj.chan{i} = addDigitalChannel(obj.task, config.nidaq.do.dev, config.nidaq.do.channel_id{i}, 'OutputOnly');
                obj.state(i) = false;
            end
            %obj.ai_chan = addAnalogInputChannel(obj.task, 'Dev2', 15, 'Voltage');
            
            %obj.task.addClockConnection('/Dev2/ai/SampleClock', '/Dev2/do/SampleClock', 'ScanClock');
            
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 0;
        end
        
        
        function data = get_toggle(obj, chan, direction)
            
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
            n_samples = round(obj.task.Rate*dur*1e-3);
            data = nan(n_samples, obj.n_chan);
            for i = 1 : obj.n_chan
                if obj.state(i)
                    data(:, i) = 1;
                elseif ~obj.state(i) && i ~= chan
                    data(:, i) = 0;
                else
                    data(:, i) = 1;
                    data(end, :) = 0;
                end
            end
        end
        
        
        function start(obj, data)
            ai_task_off = obj.ai_task.task.IsDone;
            obj.task.NumberOfScans = size(data, 1);
            obj.task.queueOutputData(data);
            obj.task.startBackground();
            
            if ai_task_off
                obj.ai_task.task.IsContinuous = 0;
                obj.ai_task.task.NumberOfScans = size(data, 1)+20;
                obj.ai_task.task.start()
                wait(obj.ai_task.task)
                obj.ai_task.task.stop()
                obj.ai_task.task.IsContinuous = 1;
            end
        end
        
        function stop(obj)
            if isvalid(obj.task)
                obj.task.stop();
            end
        end
        
        function close(obj)
            if isvalid(obj.task)
                delete(obj.task);
            end
        end
    end
end