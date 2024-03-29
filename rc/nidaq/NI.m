classdef NI < handle
    % NI Class for handling inputs and outputs on the NIDAQ.

    properties
        enabled % Boolean specifying whether the module is used.
    end
    
    properties (SetAccess = private)
        ai % :class:`AnalogInput`
        ao % :class:`AnalogOutput`
        co % :class:`CounterOutputRaw`
        do % :class:`DigitalOutputRaw`
        di % :class:`DigitalInput`
        ao_idle_offset % Determines voltage offset for analog out channels.
    end
    
    
    methods
        function obj = NI(config)
            % Constructor for a :mod:`rc.nidaq` :class:`NI`.
            % NI(config) creates the NI tasks with details
            % described in the main configuration structure.
            %
            % :param config: The main configuration structure.
        
            obj.enabled = true;
            if ~obj.enabled, return, end
            
            obj.ai = AnalogInput(config);
            obj.ao = AnalogOutput(config);
            obj.co = CounterOutputRaw(config);
            obj.do = DigitalOutputRaw(config, obj.ai.task);
            obj.di = DigitalInput(config);
        end
        
        
        function prepare_acq(obj, h_callback)
            % Prepare the analog input with a callback for acquisition.
            %
            % :param h_callback: function callback invoked by analog input task. Should be a valid function that can be passed to `addlistener(hSource, EventName, callback) <https://uk.mathworks.com/help/matlab/ref/handle.addlistener.html>`_.
        
            obj.ai.prepare(h_callback)
        end
        
          
        function start_acq(obj, clock_on)
            % Start the analog input :attr:`ai` acquisition.
            %
            % :param clock_on: A boolean value specifying whether the counter output :attr:`co` task should also be started, defaults to true.
        
            VariableDefault('clock_on', true)
            
            if ~obj.enabled, return, end
            
            if clock_on
                obj.co.start();
            end
            
            obj.ai.start();
        end
        
           
        function stop_acq(obj, clock_on)
            % Stop the analog input :attr:`ai` acquisition.
            %
            % :param clock_on: A boolean value specifying whether the counter output :attr:`co` task should also be stopped, defaults to true.
        
            VariableDefault('clock_on', true)
            
            if ~obj.enabled, return, end
            
            obj.ai.stop()
            
            if clock_on   
                obj.co.stop()
            end
        end
        
        
        function ao_write(obj, waveform)
            % Write waveforms to the analog output :attr:`ao`
            %
            % :param waveform: The data to be queued in the analog output. Should be a matrix of # samples x # AO channels with values in volts.
        
            if ~obj.enabled, return, end
            
            obj.ao.stop()
            obj.ao.write(waveform);
        end
        
        
        function ao_start(obj)
            % Start the analog output :attr:`ao` task with data queued to the analog outputs.
        
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
            % Toggle a digital output high or low.
            %
            % :param chan: The index of the channel to toggle, an integer between 1 and # :attr:`do` channels.
            % :param direction: a boolean indicating whether to toggle high (true) or low (false).
        
            if ~obj.enabled, return, end
            
            data = obj.do.get_toggle(chan, direction);
            obj.do.start(data);
        end
        
        
        function do_pulse(obj, chan, dur)
            % Pulse a digital output hight.
            %
            % :param chan: The index of the channel to pulse, an integer between 1 and # :attr:`do` channels.
            % :param dur: The duration of the pulse in milliseconds.

            if ~obj.enabled, return, end
        
            data = obj.do.get_pulse(chan, dur);
            obj.do.start(data);
        end
        
        
        function chan_names = do_names(obj)
            % Get the :attr:`do` channel names.
            %
            % :return: A cell array of channel names.
        
            if ~obj.enabled, return, end
            
            chan_names = obj.do.channel_names;
        end
        
        
        function chan_names = di_names(obj)
            % Get the :attr:`di` channel names.
            %
            % :return: A cell array of channel names.
        
            if ~obj.enabled, return, end

            chan_names = obj.di.channel_names;
        end
        
        
        function stop_all(obj)
            % Stop all tasks from running.
        
            if ~obj.enabled, return, end
            
            obj.ai.stop()
            obj.co.stop()
            obj.do.stop()
            obj.ao.stop()
        end
        
        
        function close(obj)
            % Close all tasks.
        
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
