classdef TrialStart_DoubleRotation < handle
    % VisStim class for handling digital output sent to the visual stimulus computer for disabling it.

    properties
        enabled % Boolean specifying whether the module is used.
    end
    
    properties (SetAccess = private)
        chan % Index of the channel in the configuration structure.
    end
    
    properties (SetAccess = private, Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
        state % Current state of the digital output (1 or 0).
    end

    
    methods
        function obj = TrialStart_DoubleRotation(ni, config)
            % Constructor for a :class:`rc.classes.VisStim` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
            obj.enabled = config.trailstart_trigger.enable;
            if ~obj.enabled, return, end
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.trailstart_trigger.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            % Set the state variable
            obj.state = config.trailstart_trigger.init_state;
        end
        
        function start(obj)
            % Present visual stimuli.
        
            if ~obj.enabled, return, end

            obj.ni.do_toggle(obj.chan, true);
            obj.state = true;
            pause(0.001);
            obj.ni.do_toggle(obj.chan, false);
            obj.state = false;

        end
    end
end
