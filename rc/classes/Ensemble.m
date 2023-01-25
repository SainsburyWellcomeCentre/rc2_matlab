classdef Ensemble < handle
    properties
        enabled % Boolean specifying whether to use this module
        default_speed % Default move speed
        deadband_scale = 0.2;
        ai_offset;
    end

    properties (SetAccess = private)
        gear_scale;
        ensemble_ao_channel;
        ensemble_ao_servo_value;
        ensemble_ao_scale_factor;
        gearcam_source;
        deadband;

        default_gearsource;
        default_gearscalefactor;
        default_analogdeadband;
        default_gainkpos;
    end

    properties (SetAccess = private, Hidden = true)
        
    end

    methods
        function obj = Ensemble(config)
            obj.enabled = config.ensemble.enable;
            if ~obj.enabled, return, end

            obj.default_speed = config.ensemble.default_speed;
            obj.ai_offset = config.ensemble.ai_offset;
            obj.gear_scale = config.ensemble.gear_scale;
            obj.ensemble_ao_channel = config.ensemble.ao_channel;
            obj.ensemble_ao_servo_value = config.ensemble.ao_servo_value;
            obj.ensemble_ao_scale_factor = config.ensemble.ao_scale_factor;
            obj.gearcam_source = config.ensemble.gearcam_source;
            obj.deadband = obj.deadband_scale * config.ensemble.deadband;

            obj.default_gearsource = config.ensemble.default_gearsource;
            obj.default_gearscalefactor = config.ensemble.default_gearscalefactor;
            obj.default_analogdeadband = config.ensemble.analogdeadband;
            obj.default_gainkpos = config.default_gainkpos;
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

        function result = calibrate_zero(obj, axes)
            handle = EnsembleConnect;

            % Set gear params
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

        function handle = listen(obj, axes)
            disp('LISTEN');
            handle = EnsembleConnect;

            % Setup analog output velocity tracking
            EnsembleAdvancedAnalogTrack(handle, axes, obj.ensemble_ao_channel, ...
                obj.ensemble_ao_servo_value, obj.ensemble_ao_scale_factor, 0);

            % Setup PSO output
            EnsemblePSOControl(handle, axes, EnsemblePsoMode.Reset);
            EnsemblePSOPulseCyclesAndDelay(handle, axes, 1000000, 500000, 0, 0);
            EnsemblePSOOutputPulse(handle, axes);

            % Setup gearing
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamSource, axes, obj.gearcam_source);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamScaleFactor, axes, obj.gear_scale);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamAnalogDeadband, axes, obj.deadband);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GainKpos, axes, 0);

            % Enable motion
            EnsembleMotionEnable(handle, axes);

            % Subtract offset on analog input
            EnsembleParameterSetValue(handle, EnsembleParameterId.Analog0InputOffset, axes, obj.ai_offset);

            % Set to gear mode - TODO hard coded @0 for axis
            EnsembleCommandExecute(handle, 'GEAR @0, 1');
        end

        function stop_listen(obj, sessionHandle, axes)
            disp('STOP LISTEN');
            EnsembleMotionDisable(sessionHandle, axes);

            % Pulse the digital output
            EnsemblePSOControl(sessionHandle, axes, EnsemblePsoMode.Fire);

            % Reset gear parameters to their defaults
            EnsembleCommandExecute(sessionHandle, 'GEAR @0, 0'); % Take stage out of gear mode
            EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamSource, axes, obj.default_gearsource);
            EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamScaleFactor, axes, obj.default_gearscalefactor);
            EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamAnalogDeadband, axes, obj.default_analogdeadband);
            EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GainKpos, axes, obj.default_gainkpos);
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

