classdef TriggerInput < handle
    
    properties
        ni
        teensy_channel
        soloist_channel
        current_channel
    end
    
    methods
        function obj = TriggerInput(ni, config)
            obj.ni = ni;
            
            all_channel_names = obj.ni.di_names();
            obj.teensy_channel = find(strcmp('from_teensy', all_channel_names));
            obj.soloist_channel = find(strcmp('from_soloist', all_channel_names));
            
            obj.listen_to(config.trigger_input.init_source);
        end
        
        
        function listen_to(obj, src)
            if strcmp(src, 'teensy')
                obj.current_channel = obj.teensy_channel;
            elseif strcmp(src, 'soloist')
                obj.current_channel = obj.soloist_channel;
            end
        end
        
        
        function data = read(obj)
            data = obj.ni.di.read_channel(obj.current_channel);
        end
    end
end