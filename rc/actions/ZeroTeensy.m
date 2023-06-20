classdef ZeroTeensy < handle
    % ZeroTeensy class for handling digital output sent Teensy to zero position variable.

    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    properties (Hidden  = true, SetAccess = private)
        chan % Index of the channel in the configuration structure.
    end
    
    
    methods
        
        function obj = ZeroTeensy(ni, config)
            % Constructor for a :class:`rc.actions.ZeroTeensy` action. Controls zeroing
            % of position as measure on the Teense. The Teensy code listens to a digital
            % input and resets its position to zero, when that digital input goes high.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            this_name = config.zero_teensy.do_name;
            obj.chan = find(strcmp(this_name, all_channel_names));
        end
        
        
        function zero(obj)
            % Send a 500ms pulse to tell the Teensy to zero its position.
        
            % Send a 500 ms pulse to tell the Teensy to zero its position.
            obj.ni.do_pulse(obj.chan, 500);
        end
    end
end