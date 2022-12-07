classdef StartSoloist < handle
    % StartSoloist class for handling digital output sent to the Soloist.

    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    properties (Hidden  = true, SetAccess = private)
        chan % Index of the channel in configuration.
    end
    
    
    methods
        function obj = StartSoloist(ni, config)
            % Constructor for a :class:`rc.actions.StartSoloist` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.start_soloist.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function start(obj)
            % Send a 500ms pulse to the Soloist.
        
            % Send a 500 ms pulse to tell the soloist to increase the gain.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end