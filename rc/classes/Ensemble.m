classdef Ensemble < handle
    properties
        enabled % Boolean specifying whether to use this module
        default_speed % Default move speed
    end

    properties (SetAccess = private, Hidden = true)
        
    end

    methods
        function obj = Ensemble(config)
            obj.enabled = config.ensemble.enable;
            if ~obj.enabled, return, end

            % TODO set any config values
            obj.default_speed = config.ensemble.default_speed;
        end

        function delete(obj)
            obj.abort();
        end

        function abort(obj)
            % TODO abort
        end

        function communicate(obj)
            handle = EnsembleConnect;
            EnsembleDisconnect();
        end

        function move_to(obj, axes, pos, speed, end_enabled)
            % Moves rotation stage to a relative position with given speed

            if ~obj.enabled, return, end

            % TODO - position check

            % TODO - speed check

            handle = EnsembleConnect;
            EnsembleMotionEnable(handle, axes);
            
            EnsembleMotionLinear(handle, axes, pos, speed);

            if ~end_enabled
                EnsembleMotionDisable(handle, axes)
            end

            EnsembleDisconnect();
        end
    end
end

