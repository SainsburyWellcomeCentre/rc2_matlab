classdef TeensyGain < handle
% TeensyGain Class for handling digital output sent to the Soloist.
%
%   TeensyGain Properties:
%       gain_up_state       - current state of the gain up digital output (1 or 0)
%       gain_down_state     - current state of the gain down digital output (1 or 0)
%       gain_up_chan        - index of the gain up channel in configuration
%       gain_down_chan      - index of the gain down channel in configuration
%       ni                  - handle to the NI object
%
%   TeensyGain Methods:
%       gain_up_on           - set gain up digital output high
%       gain_up_off          - set gain up digital output low
%       gain_down_on         - set gain down digital output high
%       gain_down_off        - set gain down digital output low
%
% This class controls both the gain up and gain down signals to the Teensy.

    properties
        
        gain_up_enabled
        gain_down_enabled
    end
    
    properties (SetAccess = private)
        
        gain_up_state
        gain_down_state
        gain_up_chan
        gain_down_chan
    end
    
    properties (SetAccess = private, Hidden = true)
        ni
    end
    
    
    
    methods
        
        function obj = TeensyGain(ni, config)
        %%obj = TEENSYGAIN(ni, config)
        %   Main class for controlling the digital inputs to the Teensy 
        %   The teensy code listens to two digital inputs, and changes the
        %   gain according to the state of the inputs
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
            
            obj.gain_up_enabled = config.teensy_gain_up.enable;
            obj.gain_down_enabled = config.teensy_gain_down.enable;
        
            if obj.gain_up_enabled || obj.gain_down_enabled
                obj.ni = ni;
                % The name of the digital output channel is
                all_channel_names = obj.ni.do_names();
            end
            
            if obj.gain_up_enabled
                this_name = config.teensy_gain_up.do_name;
                obj.gain_up_chan = find(strcmp(this_name, all_channel_names));
                obj.gain_up_off();
            end
            
            if obj.gain_down_enabled
                this_name = config.teensy_gain_down.do_name;
                obj.gain_down_chan = find(strcmp(this_name, all_channel_names));
                obj.gain_down_off();
            end
        end
        
        
        
        function gain_up_on(obj)
        %%GAIN_UP_ON(obj)
        %   Send the signal for teensy gain up
            if ~obj.gain_up_enabled, return, end
            obj.ni.do_toggle(obj.gain_up_chan, true);
            obj.gain_up_state = true;
        end
        
        
        
        function gain_up_off(obj)
        %%GAIN_UP_OFF(obj)
        %   Stop the signal for teensy gain up
            if ~obj.gain_up_enabled, return, end
            obj.ni.do_toggle(obj.gain_up_chan, false);
            obj.gain_up_state = false;
        end
        
        
        
        function gain_down_on(obj)
        %%GAIN_DOWN_ON(obj)
        %   Send the signal for teensy gain down
            if ~obj.gain_down_enabled, return, end
            obj.ni.do_toggle(obj.gain_down_chan, true);
            obj.gain_down_state = true;
        end
        
        
        
        function gain_down_off(obj)
        %%GAIN_DOWN_OFF(obj)
        %   Stop the signal for teensy gain down
            if ~obj.gain_down_enabled, return, end
            obj.ni.do_toggle(obj.gain_down_chan, false);
            obj.gain_down_state = false;
        end
    end
end
