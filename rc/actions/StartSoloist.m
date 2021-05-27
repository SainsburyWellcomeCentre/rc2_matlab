classdef StartSoloist < handle
    
    properties (Hidden = true)
        ni
    end
    
    properties (Hidden  = true, SetAccess = private)
        enabled
        chan
    end
    
    
    
    methods
        
        function obj = StartSoloist(ni, config)
        %%obj = STARTSOLOIST(ni, config)
        %   Main class for controlling the trigger to the soloist to start
        %   various things.
        %       Inputs:
        %           ni - object for controlling the NI hardware
        %           config - configuration structure at startup
            
            obj.enabled = config.start_soloist.enable;
            if ~obj.enabled, return, end
        
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.start_soloist.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function start(obj)
        %%START(obj)
        %   Send the signal.
        
            if ~obj.enabled, return, end
            % Send a 500 ms pulse to tell the soloist to increase the gain.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end