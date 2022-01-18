classdef VisStim < handle
% VisStim Class for handling digital output sent to the visual
% stimulus computer for disabling it
%
%   VisStim Properties:
%       enabled         - whether to use this module
%       chan            - index of the channel in configuration
%       state           - current state of the digital output (1 or 0)
%       ni              - handle to the NI object
%
%   VisStim Methods:
%       on              - set digital output high
%       off             - set digital output low

    properties (SetAccess = private)
        
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = VisStim(ni, config)
        %%obj = VISSTIM(ni, config)
        %   Main class for controlling the visual stimulus
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.visual_stimulus.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Block or unblock the treadmill depending on initial state in
            % config.
            if config.visual_stimulus.init_state
                obj.off()
            else
                obj.on()
            end
            
            % Set the state variable
            obj.state = config.visual_stimulus.init_state;
        end
        
        
        function off(obj)
        %%OFF(obj)
        %   Send screen black and reset position.
        
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        function on(obj)
        %%ON(obj)
        %   Present the corridor.
        
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
    end
end