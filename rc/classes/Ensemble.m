classdef Ensemble < handle
    % Ensemble class for handling commands to the Ensemble stage
    % controller.

    properties
        enabled % Boolean specifying whether to use this module
        default_speed % Default move speed
        deadband_scale = 0.2; % Scaling factor for the deadband.
        ai_offset; % offset in mV to add to the controller when entering gear mode.
    end

    properties (SetAccess = private)
        gear_scale; % A scaling factor applied to the Ensemble analog input when being driven in gear mode.
        ensemble_ai_channel; % The analog input channel that Ensemble will listen for waveforms on.
        ensemble_ao_channel; % The analog output channel that Ensemble will replay servo feedback on.
        ensemble_ao_servo_value; % The servo loop to replay on the ao_channel.
        ensemble_ao_scale_factor; % A scaling factor that scales the servo loop value replayed on ao_channel for display in RC2.
        gearcam_source; % The input source for gearing and camming motion on the Ensemble (0 = OpenLoop, 1 = ExternalPosition, 2 = Analog Input 0, 3 = Analog Input 1)
        deadband; % The value (in volts) of the deadband to send to the controller.

        default_gearsource; % Default value for the :attr:`gearcam_source`.
        default_gearscalefactor; % Default value for the :attr:`gear_scale`.
        default_analogdeadband; % Default value for the :attr:`deadband`.
        default_gainkpos; % Default gain Kpos value.
        all_axes; % All axes controlled by the Ensemble.
    end

    methods
        function obj = Ensemble(config)
            % Constructor for a :class:`rc.classes.Ensemble` device.
            % Interfaces with the Ensemble controller via separate using
            % the Aerotech MATLAB library.
            %
            % :param config: The main configuration structure.

            obj.enabled = config.ensemble.enable;
            if ~obj.enabled, return, end

            obj.default_speed = config.ensemble.default_speed;
            obj.ai_offset = config.ensemble.ai_offset;
            obj.gear_scale = config.ensemble.gear_scale;
            obj.ensemble_ai_channel = config.ensemble.ai_channel;
            obj.ensemble_ao_channel = config.ensemble.ao_channel;
            obj.ensemble_ao_servo_value = config.ensemble.ao_servo_value;
            obj.ensemble_ao_scale_factor = config.ensemble.ao_scale_factor;
            obj.gearcam_source = config.ensemble.gearcam_source;
            obj.deadband = obj.deadband_scale * config.ensemble.deadband;
            obj.all_axes = config.ensemble.all_axes;

            obj.default_gearsource = config.ensemble.default_gearsource;
            obj.default_gearscalefactor = config.ensemble.default_gearscalefactor;
            obj.default_analogdeadband = config.ensemble.analogdeadband;
            obj.default_gainkpos = config.default_gainkpos;
        end

        function delete(obj)
            % Destructor for :class:`rc.classes.Ensemble` device.

            obj.abort();
        end

        function abort(obj)
            % Disables motion on all axes on the Ensemble.

            handle = EnsembleConnect;
            EnsembleMotionDisable(handle, obj.all_axes);
        end

        function communicate(obj)
            % Opens a communication channel with the Ensemble. Used to test
            % connection before starting a task.

            handle = EnsembleConnect;
            EnsembleDisconnect();
        end

        function force_home(obj, axes)
            % Performs naive homing on the Ensemble axes. Ignores current
            % position and calls the standard Ensemble home.
            %
            % :param axes: The axes on the Ensemble to home.

            handle = EnsembleConnect;
            EnsembleMotionEnable(handle, axes);
            EnsembleMotionHome(handle, axes);
            EnsembleDisconnect;
        end

        function result = calibrate_zero(obj, axes)
            % Measures the analog input voltage to the Ensemble controller.
            %
            % :param axes: The axes to monitor for the analog input
            % voltage.
            % :return: The average analog input over 100 samples.

            handle = EnsembleConnect;

            % Values
            vals = nan(1,100);

            % Set gear params
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamSource, axes, obj.gearcam_source);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamScaleFactor, axes, 0);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GearCamAnalogDeadband, axes, 0);
            EnsembleParameterSetValue(handle, EnsembleParameterId.GainKpos, axes, 0);
            
            % Enable
            EnsembleMotionEnable(handle, axes);

            % Subtract offset on analog input
            EnsembleParameterSetValue(handle, EnsembleParameterId.Analog0InputOffset, axes, obj.ai_offset);

            % Set to gear mode
            EnsembleCommandExecute(handle, 'GEAR @0, 1');

            for i = 1:100
                vals(1, i) = EnsembleIOAnalogInput(handle, axes, obj.ensemble_ai_channel);
            end

            result = mean(vals);

            EnsembleDisconnect();
        end

        function move_to(obj, axes, pos, speed, end_enabled)
            % Moves rotation stage to a relative position with given speed.
            %
            % :param axes: The axes to move.
            % :param pos: The position relative from current position to
            % move.
            % :param speed: The speed of the movement.
            % :param end_enabled: Bool specifying whether axes should be
            % left enabled at the end of movement.

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
            % Sets up the Ensemble axes to listen to an incoming voltage
            % signal to drive the stage in gear mode.
            %
            % :param axes: The axes to drive with analog input.
            % :return: A handle to the active Ensemble session listening to
            % voltage input.

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
            % If Ensemble is listening for voltage input, stop it and
            % reset.
            %
            % :param sessionHandle: Handle to the Ensemble session that is
            % listening for voltage input.
            % :param axes: The axes to halt listening on.

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
            % Resets the Ensemble PSO.
            %
            % :param axes: The axes on which to reset PSO.

            handle = EnsembleConnect;
            EnsemblePSOControl(handle, axes, EnsemblePsoMode.Reset);
            EnsembleDisconnect();
        end

        function stop(obj)
            % Stops active tasks and disables motion on the Ensemble.

            if ~obj.enabled, return, end

            obj.abort();
        end
    end
end

