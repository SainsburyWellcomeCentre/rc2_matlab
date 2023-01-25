classdef Ensemble < handle
    properties
        enabled % Boolean specifying whether to use this module
        default_speed % Default move speed
    end

    properties (SetAccess = private)
        ensemble_ao_channel;
        ensemble_ao_servo_value;
        ensemble_ao_scale_factor;
    end

    properties (SetAccess = private, Hidden = true)
        
    end

    methods
        function obj = Ensemble(config)
            obj.enabled = config.ensemble.enable;
            if ~obj.enabled, return, end

            obj.default_speed = config.ensemble.default_speed;
            obj.ensemble_ao_channel = config.ensemble.ao_channel;
            obj.ensemble_ao_servo_value = config.ensemble.ao_servo_value;
            obj.ensemble_ao_scale_factor = config.ensemble.ao_scale_factor;
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

        function force_home(obj, axes)
            % performs naive homing on the Ensemble axes. Ignores current
            % position and calls the standard Ensemble home.
            handle = EnsembleConnect;
            EnsembleMotionEnable(handle, axes);
            EnsembleMotionHome(handle, axes);
            EnsembleDisconnect;
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

        function listen(obj, axes)
            handle = EnsembleConnect;

            % Setup analog output velocity tracking
            EnsembleAdvancedAnalogTrack(handle, axes, obj.ensemble_ao_channel, ...
                obj.ensemble_ao_servo_value, obj.ensemble_ao_scale_factor, 0);

            % Setup PSO output
            EnsemblePSOControl(handle, axes, EnsemblePsoMode.Reset);
            EnsemblePSOPulseCyclesAndDelay(handle, axes, 1000000, 500000, 1, 0);
            EnsemblePSOOutputPulse(handle, axes);
        end

        function reset_pso(obj, axes)
            handle = EnsembleConnect;
            EnsemblePSOControl(handle, axes, EnsemblePsoMode.Reset);
            EnsembleDisconnect();
        end

        function stop(obj)
            if ~obj.enabled, return, end

            % TODO - disable, abort etc.
        end
    end
end

