classdef Multiplexer < handle
    
    properties (Hidden = true)
        
        ni
    end
    
    properties (SetAccess = private, Hidden = true)
        
        enabled
        chan
        vals
    end
    
    
    methods
        
        function obj = Multiplexer(ni, config)
        %%obj = MULTIPLEXER(ni, config)
        %   Main class for controlling the multiplexer.
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
        
            obj.enabled = config.soloist_input_src.enable;
            if ~obj.enabled, return, end
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.soloist_input_src.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % The multiplexer is listening to the teensy when the digital
            % input is either high or low (information stored in the config
            % file)
            obj.vals.teensy = logical(config.soloist_input_src.teensy);
            obj.vals.ni = ~logical(obj.vals.teensy);
            
            % At startup, which input should we listen to
            if strcmp(config.soloist_input_src.init_source, 'teensy')
                obj.listen_to('teensy');
            else
                obj.listen_to('ni');
            end
        end
        
        
        
        function listen_to(obj, src)
        %%LISTEN_TO(obj, src)
        %   Which input should we listen to?
            % src = 'teensy' or 'ni'
            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, obj.vals.(src));
        end
    end
end