classdef NI < handle
    
    properties (SetAccess = private)
        
        enabled
        ai
        ao
        co
        do
        di
        ao_idle_offset
    end
    
    
    methods
        
        function obj = NI(config)
            
            obj.enabled = true;
            if ~obj.enabled, return, end
            
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
            if ~obj.enabled, return, end
            if clock_on
                obj.co.start();
            end
            obj.ai.start();
        end
        
        
        function stop_acq(obj, clock_on)
            VariableDefault('clock_on', true)
            if ~obj.enabled, return, end
            obj.ai.stop()
            if clock_on   
                obj.co.stop()
            end
        end
        
        
        function ao_write(obj, waveform)
            if ~obj.enabled, return, end
            obj.ao.stop()
            obj.ao.write(waveform);
        end
        
        
        function ao_start(obj)
            if ~obj.enabled, return, end
            obj.ao.stop()
            obj.ao.start()
        end
        
        
        function val = ao_task_is_running(obj)
            if ~obj.enabled, return, end
            val = obj.ao.is_running;
        end
        
        
        function val = ao_rate(obj)
            if ~obj.enabled, return, end
            val = obj.ao.rate;
        end
        
        
        function val = get.ao_idle_offset(obj)
            if ~obj.enabled, val = nan; return, end
            val = obj.ao.idle_offset;
        end
        
        
        function val = ai_rate(obj)
            if ~obj.enabled, val = nan; return, end
            val = obj.ai.rate;
        end
        
        
        function do_toggle(obj, chan, direction)
            if ~obj.enabled, return, end
            data = obj.do.get_toggle(chan, direction);
            obj.do.start(data);
        end
        
        
        function do_pulse(obj, chan, dur)
            if ~obj.enabled, return, end
            % dur in ms
            data = obj.do.get_pulse(chan, dur);
            obj.do.start(data);
        end
        
        
        function chan_names = do_names(obj)
            if ~obj.enabled, return, end
            chan_names = obj.do.channel_names;
        end
        
        
        function chan_names = di_names(obj)
            if ~obj.enabled, return, end
            chan_names = obj.di.channel_names;
        end
        
        
        function stop_all(obj)
            if ~obj.enabled, return, end
            obj.ai.stop()
            obj.co.stop()
            obj.do.stop()
            obj.ao.stop()
        end
        
        
        function close(obj)
            if ~obj.enabled, return, end
            obj.stop_all()
            obj.ai.close()
            obj.ao.close()
            obj.co.close()
            obj.do.close()
            obj.di.close()
        end
        
        
        function cfg = config(obj)
        end
    end
end