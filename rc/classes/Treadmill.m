classdef Treadmill < handle
    % Treadmill class for handling digital output sent to solenoid block on the treadmill.

    properties
        enabled % Boolean specifying whether the module is used.
    end
    
    properties (SetAccess = private)
        chan % Index of the channel in the configuration structure.
        state % Current state of the digital output (1 or 0).
    end
    
    properties (SetAccess = private, Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    methods
        function obj = Treadmill(ni, config)
            % Constructor for a :class:`rc.actions.Treadmill` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
            obj.enabled = config.treadmill.enable;
            if ~obj.enabled, return, end
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.treadmill.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Block or unblock the treadmill depending on initial state in
            % config.
            if config.treadmill.init_state
                obj.block()
            else
                obj.unblock()
            end
        end
        
        
        
        function block(obj)
            % Block the treadmill, by toggling the digital output.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, true);
            obj.state = 'up';
        end
        
        
        
        function unblock(obj)
            % Unblock the treadmill, by toggling the digital output.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, false);
            obj.state = 'down';
        end
    end
end
