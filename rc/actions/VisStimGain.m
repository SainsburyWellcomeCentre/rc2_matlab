classdef VisStimGain < handle
    % VisStimGain class for handling digital output sent to the visual
    % stimulus computer for disabling or enabling closed loop visual stim
    % with motion.
    
    properties (SetAccess = private)
        chan % Index of the channel in the configuration structure.
        state % Current state of the digital output (1 or 0).
    end
    
    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    methods
        function obj = VisStimGain(ni, config)
            % Constructor for a :class:`rc.actions.VisStimGain` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.vis_stim_gain.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
            
            % Enable or disable closed loop depending on initial state in
            % config
            if config.vis_stim_gain.init_state
                obj.off()
            else
                obj.on()
            end
        end
        
        function off(obj)
            obj.ni.do_toggle(obj.chan, false);
        end
        
        function on(obj)
            obj.ni.do_toggle(obj.chan, true);
        end
    end
end

