classdef Position < handle
    % Position class for handling the assessment of position of the stage during a trial.

    properties (SetAccess = private)
        dt = nan % 1/sampling rate of velocity trace.
        position = 0 % Current position estimate.
        deadband = nan % Voltage value below which value is not integrated.
        integrate_on = false % Boolean specifying whether we are currently integrating the trace.
    end
    
    
    methods       
        function obj = Position(config)
            % Constructor for :class:`rc.classes.Position` class.
            % Controls the assessment of position as determined on the control machine.
            % Integrates velocity trace (treadmill position). Mainly designed for training phases
            % where critical assessment of position is not necessary (i.e. position is not calculated on the teensy and a trigger sent upon reaching a particular position).
            %
            % :param config: The main configuration structure.
            
            if ~config.nidaq.ai.enable
                return
            end
        
            % require the time interval to calculate position
            obj.dt = 1/config.nidaq.rate;
            
            % try to use the same deadband as the soloist
            filtered_idx = ismember(config.nidaq.ai.channel_names, {'filtered_teensy', 'gain_teensy'});
            obj.deadband = config.soloist.deadband * config.nidaq.ai.scale(filtered_idx);  % TODO: Move to config
        end
        
        
        
        function integrate(obj, velocity)
            % Take the current velocity vector and integrate it to update.
            %
            % :param velocity: The current velocity vector.
        
            % if we are not integrating don't do anything
            if ~obj.integrate_on; return; end
            
            % convert velocity to cm
            obj.position = obj.position + sum(velocity(abs(velocity) > obj.deadband))*obj.dt;
            
            % printing is useful for debugging
            %fprintf('%.2f\n', obj.position);
        end
        
        
        
        function start(obj)
            % Set the position to zero and set :attr:`integrate_on` to true.
            obj.position = 0;
            obj.integrate_on = true;
        end
        
        
        
        function stop(obj)
            % Stop integrating, set :attr:`integrate_on` to false.
            obj.integrate_on = false;
        end
    end
end
