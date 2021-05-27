classdef Pump < handle
    
    properties (SetAccess = private)
        
        enabled
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = Pump(ni, config)
            
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
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        function off(obj)
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
        
        
        function pulse(obj, duration)
            if ~obj.enabled, return, end
            obj.ni.do_pulse(obj.chan, duration);
        end
    end
end