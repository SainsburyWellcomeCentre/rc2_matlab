classdef ZeroTeensy < handle
% ZeroTeensy Class for handling digital output sent Teensy to zero position
% variable.
%
%   ZeroTeensy Properties:
%       enabled         - whether to use this module
%       chan            - index of the channel in configuration
%       ni              - handle to the NI object
%
%   ZeroTeensy Methods:
%       zero           - send a trigger pulse to the Teensy
%
% On `start` a 500ms pulse is sent to the soloist.

    properties (Hidden = true)
        ni
    end
    
    properties (Hidden  = true, SetAccess = private)
        enabled
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
            
            obj.enabled = config.zero_teensy.enable;
            if ~obj.enabled, return, end
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.zero_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function zero(obj)
        %%ZERO(obj)
        %   Send the signal.
        
            if ~obj.enabled, return, end
            
            % Send a 500 ms pulse to tell the Teensy to zero its position.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end