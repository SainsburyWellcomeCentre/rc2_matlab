classdef Position < handle
% Position Class for handling the assessment of position of the stage
% during a trial
%
%   Position Properties:
%       dt                  - 1/sampling rate of velocity trace
%       position            - current position estimate
%       deadband            - voltage value below which we do not integrate the value
%       integrate_on        - true or false, are we currently integrating the trace
%
%   Position Methods:
%       integrate           - perform integration of new velocity data
%       start               - set position to zero and start integrating
%       stop                - stop integrating

    properties (SetAccess = private)
        
        dt = nan
        
        position = 0
        deadband = nan
        integrate_on = false
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
        %INTEGRATE(obj, data)
        %   Take the current velocity vector and integrate it to update 
        %   the position.
        
            % if we are not integrating don't do anything
            if ~obj.integrate_on; return; end
            
            % convert velocity to cm
            obj.position = obj.position + sum(velocity(abs(velocity) > obj.deadband))*obj.dt;
            
            % printing is useful for debugging
            %fprintf('%.2f\n', obj.position);
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
