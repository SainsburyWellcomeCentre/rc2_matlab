classdef TeensyGain < handle
    % TeensyGain Class for handling digital output sent to the Soloist.

    properties (SetAccess = private)
        gain_up_state % Current state of the gain up digital output (1 or 0).
        gain_down_state % Current state of the gain down digital output (1 or 0).
    end
    
    properties (Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    properties (Hidden  = true, SetAccess = private)
        gain_up_chan % Index of the gain up channel in configurations structure.
        gain_down_chan % Index of the gain down channel in configurations structure.
    end

    
    methods
        function obj = TeensyGain(ni, config)
            % Constructor for a :class:`rc.actions.TeensyGain` action. Teensy listens to two digital inputs and changes gain according to the state of those inputs.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
            
            obj.ni = ni;
            
            % The name of the digital output channel is
            all_channel_names = obj.ni.do_names();
            
            this_name = config.teensy_gain_up.do_name;
            obj.gain_up_chan = find(strcmp(this_name, all_channel_names));
            obj.gain_up_off();
            
            this_name = config.teensy_gain_down.do_name;
            obj.gain_down_chan = find(strcmp(this_name, all_channel_names));
            obj.gain_down_off();
        end
        
        
        function gain_up_on(obj)
            % Send signal to increase gain on Teensy.

            obj.ni.do_toggle(obj.gain_up_chan, true);
            obj.gain_up_state = true;
        end
        
        
        function gain_up_off(obj)
            % Stop the signal to increase gain on Teensy.
        
            obj.ni.do_toggle(obj.gain_up_chan, false);
            obj.gain_up_state = false;
        end
        
        
        function gain_down_on(obj)
            % Send signal to decrease gain on Teensy.
        
            obj.ni.do_toggle(obj.gain_down_chan, true);
            obj.gain_down_state = true;
        end
        
        
        function gain_down_off(obj)
            % Stop the signal to decrease gain on Teensy.
        
            obj.ni.do_toggle(obj.gain_down_chan, false);
            obj.gain_down_state = false;
        end
    end
end