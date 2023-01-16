classdef DisableTeensy < handle
    % DisableTeensy class for handling digital output sent to the Teensy for disabling it.

    properties (SetAccess = private)
        enabled % Boolean specifying whether the module is used.
        chan % Index of the channel in the configuration structure.
        state % Current state of the digital output (1 or 0).
    end
    
    properties (SetAccess = private, Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    methods
        function obj = DisableTeensy(ni, config)
            % Constructor for a :class:`rc.classes.DisableTeensy` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
            obj.enabled = config.disable_teensy.enable;
            if ~obj.enabled, return, end
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.disable_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Enable or disable velocity output on Teensy according to
            % initial state config
            if config.disable_teensy.init_state
                obj.on()
            else
                obj.off()
            end
            
            % Set the state variable
            obj.state = config.disable_teensy.init_state;
        end
        
        
        
        function on(obj)
            % Disable velocity output on the Teensy.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        
        function off(obj)
            % Enable velocity output on Teensy.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
    end
end
