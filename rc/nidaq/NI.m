classdef NI < handle
    
    properties
        ai
        ao
        co
        do
    end
    
    
    methods
        
        function obj = NI(config)
            
            obj.ai = AnalogInput(config);
            obj.ao = AnalogOutput(config);
            obj.co = CounterOutputRaw(config);
            obj.do = DigitalOutputRaw(config, obj.ai.task);
        end
        
        
        function prepare_acq(obj, fname, h_callback)
            obj.ai.prepare(fname, h_callback)
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
            data = obj.do.get_toggle(chan, direction);
            obj.do.start(data);
        end
        
        
        function do_pulse(obj, chan, dur)
            % dur in ms
            data = obj.do.get_pulse(chan, dur);
            obj.do.start(data);
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