classdef Position < handle
    
    properties (SetAccess = private)
        
        dt
        
        position = 0
        deadband
        integrate_on
    end
    
    
    methods
        
        function obj = Position(config)
        %%obj = POSITION(config)
        % This class controls the assessment of "position" as determined on
        % the PC. It is charged with integrating the velocity trace 
        % (treadmill position). It is mainly designed for the training
        % phases where critical assessment of position is not necessary
        % (i.e. position is not calculated on the teensy and a trigger sent
        % upon reaching a particular position)
        % Inputs:
        %       config - main config structures
            
            % require the time interval to calculate position
            obj.dt = 1/config.nidaq.rate;
            
            % this ignores any velocity within "deadband" limits
            obj.deadband = config.position.deadband;
        end
        
        
        function integrate(obj, velocity)
        %INTEGRATE(obj, data)
        %   Take the current velocity vector and integrate it to update 
        %   the position.
        
            % if we are not integrating don't do anything
            if ~obj.integrate_on; return; end
            
            % convert velocity to cm
            obj.position = obj.position + sum(velocity(abs(velocity) > obj.deadband))*obj.dt;
            
            % printing is useful for debugging
            fprintf('%.2f\n', obj.position);
        end
        
        
        function start(obj)
        %%START(obj)
        %   Set the position to zero and set integrate on.
            obj.position = 0;
            obj.integrate_on = true;
        end
        
        
        function stop(obj)
        %%STOP(obj)
        %   Stop integrating.
            obj.integrate_on = false;
        end
    end
end