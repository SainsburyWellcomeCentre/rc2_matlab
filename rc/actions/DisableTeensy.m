classdef DisableTeensy < handle
    
    properties (SetAccess = private)
        
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = DisableTeensy(ni, config)
        %%obj = DISABLETEENSY(ni, config)
        %   Main class for controlling the disabling of teensy
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.disable_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Enable or disable velocity output on Teensy according to
            % initial state config
            if config.disable_teensy.init_state
                obj.on()
            else
                obj.off()
            end
            
            % Set the state variable
            obj.state = config.disable_teensy.init_state;
        end
        
        
        function on(obj)
        %%ON(obj)
        %   Disable velocity output on Teensy
        
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        
        function off(obj)
        %%OFF(obj)
        %   Do not disable: i.e. enable velocity output on Teensy
        
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
    end
end
