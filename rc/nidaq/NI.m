classdef NI < handle
    
    properties
        ai
        ao
        co
        do
        do_timer
    end
    
    
    methods
        
        function obj = NI(config)
            
            obj.ai = AnalogInput(config);
            obj.ao = AnalogOutput(config);
            obj.co = CounterOutputRaw(config);
            obj.do = DigitalOutput(config, obj.ai);
        end
        
        function prepare_acq(obj, fname, rate, h_callback)
            obj.ai.prepare(fname, rate, h_callback)
        end
        
        function start_acq(obj)
            obj.co.start();
            obj.ai.start();
        end
        
        function stop_acq(obj)
            obj.ai.stop()
            obj.co.stop()
        end
        
        function ao_write(obj, waveform)
            obj.ao.stop()
            obj.ao.write(waveform)
        end
        
        function ao_start(obj)
            obj.ao.stop()
            obj.ao.start()
        end
        
        function do_toggle(obj, chan, direction)
            obj.do.stop()
            data = obj.do.get_toggle(chan, direction);
            obj.do.task.outputSingleScan(data(1, :))
            %obj.do.start(data)
        end
        
        function do_pulse(obj, chan, dur)
            % dur in ms
            obj.do.stop()
            data = obj.do.get_pulse(chan, dur);
            obj.do_timer = timer();
            obj.do_timer.StartDelay = 0.05;
            obj.do_timer.TimerFcn = @(x, y)obj.stop_timer(x, y, data(end, :));
            obj.do.task.outputSingleScan(data(1, :))
            start(obj.do_timer)
            %obj.do.start(data)
        end
        
        function stop_timer(obj, ~, ~, data)
            obj.do.task.outputSingleScan(data);
        end
            
        
        function chan_names = do_names(obj)
            chan_names = obj.do.channel_names;
        end
        
        
        function stop_all(obj)
            obj.ai.stop()
            obj.co.stop()
            obj.do.stop()
            obj.ao.stop()
        end
        
        
        function close(obj)
            obj.stop_all()
            obj.ai.close()
            obj.ao.close()
            obj.co.close()
            obj.do.close()
        end
    end
end