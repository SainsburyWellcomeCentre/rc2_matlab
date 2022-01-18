classdef Pump < handle
% Pump Class for handling digital output pump
%
%   Pump Properties:
%       enabled         - whether to use this module
%       chan            - index of the channel in configuration
%       state           - current state of the digital output (1 or 0)
%       ni              - handle to the NI object
%
%   Pump Methods:
%       on              - set digital output high
%       off             - set digital output low
%       pulse           - pulse digital output high

    properties
        
        enabled
    end
    
    properties (SetAccess = private)
        
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = Pump(ni, config)
        % Pump
        %
        %   Pump(NI, CONFIG)
        %   
        %       Inputs:
        %           NI - object of class NI, for controlling the NI hardware
        %           CONFIG - configuration structure at startup    
        
            obj.enabled = config.pump.enable;
            if ~obj.enabled, return, end
            
            obj.ni = ni;
            
            all_channel_names = obj.ni.do_names();
            this_name = config.pump.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            if config.pump.init_state
                obj.on()
            else
                obj.off()
            end
            
            obj.state = config.pump.init_state;
        end
        
        
        
        function on(obj)
        %%on Send digital output to pump high
        %
        %   on()
        
            if ~obj.enabled, return, end
            
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        
        function off(obj)
        %%off Send digital output to pump high
        %
        %   off()
        
            if ~obj.enabled, return, end
            
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
        
        
        
        function pulse(obj, duration)
        %%pulse Pulse the digital output to the pump high
        %
        %   pulse(DURATION) Send digital output high for DURATION
        %   milliseconds.
        
            if ~obj.enabled, return, end
            
            obj.ni.do_pulse(obj.chan, duration);
        end
    end
end
