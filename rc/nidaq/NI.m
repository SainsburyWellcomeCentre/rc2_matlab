classdef NI < handle
% NI Class for handling inputs and outputs on the NIDAQ
%
%   NI Properties:
%       enabled         - whether to use this module
%       ai              - object of class AnalogInput
%       ao              - object of class AnalogOutput
%       co              - object of class CounterOutputRaw
%       do              - object of class DigitalOutputRaw
%       di              - object of class DigitalInput
%
%   NI Methods:
%       prepare_acq     - prepare the analog input with a callback for acquisition
%       start_acq       - start the analog input acquisition
%       stop_acq        - stop the analog input acquisition
%       ao_write        - write waveforms to the analog output
%       ao_start        - start the analog output tasks
%       do_toggle       - toggle a digital output high or low
%       do_pulse        - pulse a digital output high
%       do_names        - return the digital output channel names
%       di_names        - return the digital input channel names
%       stop_all        - stop all tasks from running
%       close           - clear all tasks
%
%   See also: AnalogInput, AnalogOutput, CounterOutputRaw,
%   DigitalOutputRaw, DigitalInput

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
        % NI
        %
        %   NI(CONFIG) creates the object with
        %   the details described in CONFIG.
        %
        %   See README for details on the configuration.
        
            obj.enabled = true;
            if ~obj.enabled, return, end
            
            obj.ai = AnalogInput(config);
            obj.ao = AnalogOutput(config);
            obj.co = CounterOutputRaw(config);
            obj.do = DigitalOutputRaw(config, obj.ai.task);
            obj.di = DigitalInput(config);
        end
        
        
        
        function prepare_acq(obj, h_callback)
        %%prepare_acq Prepare the analog input with a callback for acquisition
        %
        %   prepare_acq(CALLBACK_HANDLE) setups the callback called by the
        %   analog input task. CALLBACK_HANDLE is the handle to a function
        %   which can be any valid function that can be passed to
        %   `addlistener(task, 'DataAvailable', CALLBACK_HANDLE)`
        %
        %   See also: AnalogInput.prepare
        
            obj.ai.prepare(h_callback)
        end
        
        
        
        function start_acq(obj, clock_on)
        %%start_acq Start the analog input acquisition
        %
        %   start_acq(START_COUNTER_OUTPUT) starts the analog input
        %   acquisition. START_COUNTER_OUTPUT is optional and should be a
        %   boolean determining whether to also start the counter output
        %   task. By default it is true, to start the task.
        %
        %   See also: AnalogInput.start, CounterOutputRaw.start
        
            VariableDefault('clock_on', true)
            
            if ~obj.enabled, return, end
            
            if clock_on
                obj.co.start();
            end
            
            obj.ai.start();
        end
        
        
        
        function stop_acq(obj, clock_on)
        %%stop_acq Stop the analog input acquisition
        %
        %   stop_acq(STOP_COUNTER_OUTPUT) stops the analog input
        %   acquisition. STOP_COUNTER_OUTPUT is optional and should be a
        %   boolean determining whether to also stop the counter output
        %   task. By default it is true, to stop the task.
        %
        %   See also: AnalogInput.stop, CounterOutputRaw.stop
        
            VariableDefault('clock_on', true)
            
            if ~obj.enabled, return, end
            
            obj.ai.stop()
            
            if clock_on   
                obj.co.stop()
            end
        end
        
        
        
        function ao_write(obj, waveform)
        %%ao_write Write waveforms to the analog output
        %
        %   ao_write(DATA) queues the data in DATA to the analog outputs. DATA
        %   should be a # samples x # AO channels matrix with values in
        %   volts to output on the analog outputs.
        %
        %   See also: AnalogOuput.write
        
            if ~obj.enabled, return, end
            
            obj.ao.stop()
            obj.ao.write(waveform);
        end
        
        
        
        function ao_start(obj)
        %%ao_start Start the analog output tasks
        %
        %   ao_start() starts outputing the data queued to the analog
        %   outputs.
        %
        %   See also: ao_write, AnalogOutput.start
        
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
        %%do_toggle Toggle a digital output high or low
        %
        %   do_toggle(CHANNEL_IDX, VALUE) toggles the value on channel
        %   determined by CHANNEL_IDX (an integer between 1 and # DO
        %   channels), to VALUE, a boolean indicating whether to send high
        %   (true) or low (false).
        
            if ~obj.enabled, return, end
            
            data = obj.do.get_toggle(chan, direction);
            obj.do.start(data);
        end
        
        
        
        function do_pulse(obj, chan, dur)
        %%do_pulse Pulse a digital output high
        %
        %   do_pulse(CHANNEL_IDX, DURATION) pulses the channel
        %   determined by CHANNEL_IDX (an integer between 1 and # DO
        %   channels), for DURATION, a value in milliseconds.

            if ~obj.enabled, return, end
            % dur in ms
            
            data = obj.do.get_pulse(chan, dur);
            obj.do.start(data);
        end
        
        
        
        function chan_names = do_names(obj)
        %%do_names Return the digital output channel names
        %
        %   CHANNEL_NAMES = do_names()
        
            if ~obj.enabled, return, end
            
            chan_names = obj.do.channel_names;
        end
        
        
        
        function chan_names = di_names(obj)
        %%di_names Return the digital input channel names
        %
        %   CHANNEL_NAMES = di_names()
        
            if ~obj.enabled, return, end

            chan_names = obj.di.channel_names;
        end
        
        
        
        function stop_all(obj)
        %%stop_all Stop all tasks from running
        %
        %   stop_all()
        
            if ~obj.enabled, return, end
            
            obj.ai.stop()
            obj.co.stop()
            obj.do.stop()
            obj.ao.stop()
        end
        
        
        
        function close(obj)
        %%close Clear all tasks
        %
        %   close()
        
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
