classdef Multiplexer < handle
    % Multiplexer class for handling the behaviour of the multiplexer.

    properties (SetAccess = private)
        enabled % Boolean specifying whether the module is used.
        chan % Index of the channel in the digital output configuration.
        vals % Structure with fields ``teensy`` and ``ni``. Indicates which input the multiplexer interfaces which when the digitial input to the mux is high or low.
    end

    properties (SetAccess = private, Hidden = true)
        ni % Handle to the :class:`rc.nidaq.NI` object.
    end
    
    
    
    methods
        function obj = Multiplexer(ni, config)
            % Constructor for a :class:`rc.classes.Multiplexer` action.
            %
            % :param ni: :class:`rc.nidaq.NI` object.
            % :param config: The main configuration file.
        
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
            % Sets the multiplexer interface source.
            %
            % :param src: Device to listen to: 'teensy' or 'ni'.

            if ~obj.enabled, return, end
            obj.ni.do_toggle(obj.chan, obj.vals.(src));
        end
    end
end
