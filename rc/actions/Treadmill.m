classdef Treadmill < handle
    
    properties (SetAccess = private)
        
        chan
        state
    end
    
    properties (Hidden = true)
        
        ni
    end
    
    
    
    methods
        
        function obj = Treadmill(ni, config)
        %%obj = TREADMILL(ni, config)
        %   Main class for controlling the treadmill/solenoid
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.treadmill.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Block or unblock the treadmill depending on initial state in
            % config.
            if config.treadmill.init_state
                obj.block()
            else
                obj.unblock()
            end
            
            % Set the state variable
            obj.state = config.treadmill.init_state;
        end
        
        
        function block(obj)
        %%BLOCK(obj)
        %   Block the treadmill, by toggling the digital output.
        
            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
        end
        
        function unblock(obj)
        %%UNBLOCK(obj)
        %   Unblock the treadmill, by toggling the digital output.
        
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;
        end
    end
end