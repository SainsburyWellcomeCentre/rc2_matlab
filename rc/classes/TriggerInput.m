classdef TriggerInput < handle
% TriggerInput Class for handling digital input sent from Teensy and
% Soloists
%
%   TriggerInput Properties:
%       enabled         - whether to use this module
%       teensy_channel  - index of the teensy channel in digital input configuration
%       soloist_channel - index of the soloist channel in digital input configuration
%       current_channel - current channel to listen to
%       ni              - handle to the NI object
%
%   TriggerInput Methods:
%       listen_to       - set which channel to listen to
%       read            - read the state of the channel currently listened to

    
    properties
        
        enabled
    end
    
    properties (SetAccess = private)
        
        teensy_channel
        soloist_channel
        current_channel
    end
    
    properties (SetAccess = private, Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = TriggerInput(ni, config)
        %%obj = TRIGGERINPUT(ni, config)
        %   There is a single trigger input class which listens to either
        %   of two digital inputs. We could potentially set up two separate
        %   objects, but deal with both in the same object.
        
            obj.enabled = config.trigger_input.enable;
            if ~obj.enabled, return, end
            
            obj.ni = ni;
            
            % The name of the digital input channel is
            all_channel_names = obj.ni.di_names();
            obj.teensy_channel = find(strcmp('from_teensy', all_channel_names));
            obj.soloist_channel = find(strcmp('from_soloist', all_channel_names));
            
            % We are initially listening on the input set in config.
            obj.listen_to(config.trigger_input.init_source);
        end
        
        
        
        function listen_to(obj, src)
        %%LISTEN_TO(obj, src)
        %   Set the current channel to listen to one of the two inputs.
        %   This could be made more generic.
        
            if ~obj.enabled, return, end
            
            if strcmp(src, 'teensy')
                obj.current_channel = obj.teensy_channel;
            elseif strcmp(src, 'soloist')
                obj.current_channel = obj.soloist_channel;
            end
        end
        
        
        
        function data = read(obj)
        %%data = READ(obj)
        %   Read the state of the channel we are currently listening to.
        %       data is a boolean value, true (high) or false (low)
        
            if ~obj.enabled, return, end
            data = obj.ni.di.read_channel(obj.current_channel);
        end
    end
end
