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
            
            obj.vals.teensy = logical(config.soloist_input_src.teensy);
            obj.vals.ni = ~logical(obj.vals.teensy);
            
            if strcmp(config.soloist_input_src.init_source, 'teensy')
                obj.listen_to('teensy');
            else
                obj.listen_to('ni');
            end
        end
        
        
        function listen_to(obj, src)
            % src = 'teensy' or 'ni'
            obj.ni.do_toggle(obj.chan, obj.vals.(src));
        end
    end
end