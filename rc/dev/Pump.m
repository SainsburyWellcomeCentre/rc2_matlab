classdef Pump < handle
    
    properties (SetAccess = private)
        
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = Pump(ni, config)
            
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
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        function off(obj)
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
        
        
        function pulse(obj, duration)
            obj.ni.do_pulse(obj.chan, duration);
        end
    end
end