classdef TriggerInput < handle
    % TriggerInput class for handling digital input sent from Teensy and Soloists.

    properties
        enabled % Boolean specifying whether the module is used.
    end
    
    properties (SetAccess = private)
        teensy_channel % Index of the Teensy channel in the digital input configuration.
        soloist_channel % Index of the Soloist channel in the digital input configuration.
        current_channel % Current channel to listen to.
    end
    
    properties (SetAccess = private, Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    
    methods
        
        function obj = TriggerInput(ni, config)
            % Constructor for a :class:`rc.actions.TriggerInput` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
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
            % Set the current channel to listen to one of the two inputs.
            %
            % :param src: The channel to listen to: 'teensy' or 'soloist'.

            if ~obj.enabled, return, end
            
            if strcmp(src, 'teensy')
                obj.current_channel = obj.teensy_channel;
            elseif strcmp(src, 'soloist')
                obj.current_channel = obj.soloist_channel;
            end
        end
        
        
        
        function data = read(obj)
            % Read the state of the channel currently being listened to.
            %
            % :return: State of the channel as boolean value: true (high) or false (low).
        
            if ~obj.enabled, return, end
            data = obj.ni.di.read_channel(obj.current_channel);
        end
    end
end
