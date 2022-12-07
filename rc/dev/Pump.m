classdef Pump < handle
    % Pump class for handling digital output pump.

    properties (SetAccess = private)
        chan % Index of the addressed channel.
        state % Current state of the digital output (1 or 0).
    end
    
    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    methods
        function obj = Pump(ni, config)
            % Constructor for a :class:`rc.dev.Pump` device.
            %
            % :param ni: :class:`rc.nidaq.NI` object for controlling NI hardware.
            % :param config: The main configuration structure. 
        
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
            % Send digital output to pump: high.
        
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        function off(obj)
            % Send digital output to pump: low.
        
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
        
        
        function pulse(obj, duration)
            % Pulse the digital output to pump: high.
            %
            % :param duration: Pulse duration in milliseconds.
        
            obj.ni.do_pulse(obj.chan, duration);
        end
    end
end
