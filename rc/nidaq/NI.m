classdef NI < handle
    
    properties
        ai
        ao
        co
        do
        di
    end
    
    
    methods
        
        function obj = NI(config)
            
            obj.ai = AnalogInput(config);
            obj.ao = AnalogOutput(config);
            obj.co = CounterOutputRaw(config);
            obj.do = DigitalOutputRaw(config, obj.ai.task);
            obj.di = DigitalInput(config);
        end
        
        
        function prepare_acq(obj, h_callback)
            obj.ai.prepare(h_callback)
        end
        
        
        function start_acq(obj, clock_on)
            VariableDefault('clock_on', true)
            if clock_on
                obj.co.start();
            end
            obj.ai.start();
        end
        
        
        function stop_acq(obj, clock_on)
            VariableDefault('clock_on', true)
            obj.ai.stop()
            if clock_on   
                obj.co.stop()
            end
        end
        
        
        function ao_write(obj, waveform, offset)
            
            % don't apply any offset by default
            VariableDefault('offset', 0);
            
            obj.ao.stop()
            obj.ao.write(waveform, offset);
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
        
        
        function chan_names = di_names(obj)
            chan_names = obj.di.channel_names;
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
            obj.di.close()
        end
    end
end