classdef Multiplexer < handle
    
    properties
        ni
        chan
        vals
    end
    
    
    methods
        function obj = Multiplexer(ni, config)
            obj.ni = ni;
            
            all_channel_names = obj.ni.do_names();
            this_name = config.soloist_input_src.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            if strcmp(config.soloist_input_src.init_source, 'teensy')
                obj.vals.teensy = true;
                obj.vals.ni = false;
            else
                 obj.vals.teensy = false;
                obj.vals.ni = true;
            end
        end
        
        
        function listen_to(obj, src)
            % src = 'teensy' or 'ni'
            obj.ni.do_toggle(obj.chan, obj.vals.(src));
        end
    end
end