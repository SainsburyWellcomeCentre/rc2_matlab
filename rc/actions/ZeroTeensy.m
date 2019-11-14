classdef ZeroTeensy < handle
    
    properties (Hidden = true)
        ni
    end
    
    properties (Hidden  = true, SetAccess = private)
        chan
    end
    
    
    
    methods
        
        function obj = ZeroTeensy(ni, config)
        %%obj = ZEROTEENSY(ni, config)
        %   Main class for controlling the zeroing of the position as 
        %   measured on the teensy. The teensy code listens to a digital
        %   input, and resets its position to zero, when that digital input
        %   goes high.
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.zero_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function zero(obj)
        %%ZERO(obj)
        %   Send the signal.
        
            % Send a 500 ms pulse to tell the Teensy to zero its position.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end