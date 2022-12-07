classdef VisStim < handle
    % VisStim class for handling digital output sent to the visual stimulus computer for disabling it.

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
        function obj = VisStim(ni, config)
            % Constructor for a :class:`rc.actions.VisStim` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
            obj.enabled = config.visual_stimulus.enable;
            if ~obj.enabled, return, end
            
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
            % Send screen to black and reset position.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        
        function on(obj)
            % Present the corridor.
        
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
    end
end
