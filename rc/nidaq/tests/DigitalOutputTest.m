classdef DigitalOutputTest < handle
    
    properties
        task
        ai_task
        channel_names
        chan = {}
        n_chan
        state
    end
    
    
    methods
        
        function obj = DigitalOutputTest(config, ai_task)
            
            obj.task = TaskTest();
            obj.ai_task = ai_task;
            obj.n_chan = length(config.nidaq.do.channel_names);
            for i = 1 : obj.n_chan
                obj.channel_names{i} = config.nidaq.do.channel_names{i};
                obj.chan{i} = addDigitalChannel(obj.task, config.nidaq.do.dev, config.nidaq.do.channel_id(i), 'OutputOnly');
                obj.state(i) = false;
            end
            
            obj.task.addClockConnection('/Dev2/ai/SampleClock', '/Dev2/do/SampleClock', 'ScanClock');
            
            obj.task.Rate = config.nidaq.rate;
            obj.task.IsContinuous = 1;
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
                obj.ai_task.task.startBackground()
                %wait(obj.ai_task.task)
                obj.ai_task.task.stop()
                obj.ai_task.task.IsContinuous = 1;
            end
        end
        
        function stop(obj)
            obj.task.stop()
        end
        
        function close(obj)
            obj.task.close()
        end
    end
end