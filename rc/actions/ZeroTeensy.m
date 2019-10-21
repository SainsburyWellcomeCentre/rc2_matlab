classdef ZeroTeensy < handle
    
    properties
        ni
        chan
    end
    
    methods
        
        function obj = ZeroTeensy(ni, config)
            
            obj.ni = ni;
            
            all_channel_names = obj.ni.do_names();
            this_name = config.zero_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function zero(obj)
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end