classdef Treadmill < handle
    
    properties
        ni
        chan
        current_state
    end
    
    methods
        
        function obj = Treadmill(ni, config)
            
            obj.ni = ni;
            
            all_channel_names = obj.ni.do_names();
            this_name = config.treadmill.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            if config.treadmill.init_state
                obj.block()
            else
                obj.unblock()
            end
            obj.current_state = config.treadmill.init_state;
        end
        
        
        function block(obj)
            obj.ni.do_toggle(obj.chan, true);
            obj.current_state = true;
        end
        
        function unblock(obj)
            obj.ni.do_toggle(obj.chan, false);
            obj.current_state = false;
        end
    end
end