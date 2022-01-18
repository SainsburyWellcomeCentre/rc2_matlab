classdef StartSoloist < handle
% StartSoloist Class for handling digital output sent to the Soloist.
%
%   StartSoloist Properties:
%       enabled         - whether to use this module
%       chan            - index of the channel in configuration
%       ni              - handle to the NI object
%
%   StartSoloist Methods:
%       start           - send a trigger pulse to the soloist
%
% On `start` a 500ms pulse is sent to the soloist.
%
% TODO: the trigger can be quite general use, so perhaps rename
% TriggerSoloist

    properties (Hidden = true)
        ni
    end
    
    properties (Hidden  = true, SetAccess = private)
        chan
    end
    
    
    
    methods
        
        function obj = StartSoloist(ni, config)
        %%obj = STARTSOLOIST(ni, config)
        %   Main class for controlling the trigger to the soloist to start
        %   various things.
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.start_soloist.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function start(obj)
        %%START(obj)
        %   Send the signal.
        
            % Send a 500 ms pulse to tell the soloist to increase the gain.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end