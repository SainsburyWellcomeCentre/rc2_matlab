classdef Ensemble_DoubleRotation < handle
    % Ensemble class for handling commands to the Ensemble stage controller
    % in rotation tasks.

    properties
        enabled                 % Boolean specifying whether to use this module
        default_position        % Default position to move to (deg)
        default_speed           % Default move speed (deg/sec)
        deadband_scale = 0.2;   % Scaling factor for the deadband.
        ai_offset               % offset in mV to add to the controller when entering gear mode.
        target_axes             % axes to be controlled. Central only = [0, NaN]. Outer only = [NaN, 1]. Both = [0, 1]. Neither = [NaN, NaN].
        homed
    end

    properties (SetObservable = true)
        online     % while online, Ensemble control via GUI is disabled
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
        default_homeSetup; % Default HomeSetup Parameter
        all_axes; % All axes controlled by the Ensemble.

        handle;
    end

    methods
        function obj = Ensemble_DoubleRotation(config)
            % Constructor for a :class:`rc.classes.Ensemble` device.
            % Interfaces with the Ensemble controller via separate using
            % the Aerotech MATLAB library.
            %
            % :param config: The main configuration structure.

            obj.enabled = config.ensemble.enable;
            if ~obj.enabled, return, end
            
            obj.default_position = config.ensemble.default_position;
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
            obj.set_targetaxes(config.ensemble.target_axes);
            obj.set_homed([1,length(obj.all_axes)],false);
            obj.set_online(obj.all_axes, false);

            obj.default_gearsource = config.ensemble.default_gearsource;
            obj.default_gearscalefactor = config.ensemble.default_gearscalefactor;
            obj.default_analogdeadband = config.ensemble.analogdeadband;
            obj.default_gainkpos = config.default_gainkpos;

            obj.default_homeSetup = config.ensemble.default_homeSetup;
            obj.handle = EnsembleConnect;
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(1), obj.default_homeSetup);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(2), obj.default_homeSetup);
            EnsembleDisconnect();
        end

        function delete(obj)
            % Destructor for :class:`rc.classes.Ensemble` device.
            obj.abort_all();
        end

        function abort(obj)
            % Disables motion on selected axes on the Ensemble.
            obj.handle = EnsembleConnect;
            axes = obj.target_axes(~isnan(obj.target_axes));
            EnsembleMotionDisable(obj.handle, axes);
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
            EnsembleDisconnect();
        end

        function abort_all(obj)
            % Disables motion on all axes on the Ensemble.
            obj.handle = EnsembleConnect;
            EnsembleMotionDisable(obj.handle, obj.all_axes);
            EnsembleDisconnect();
        end

        function communicate(obj)
            % Opens a communication channel with the Ensemble. Used to test
            % connection before starting a task.

            if ~obj.enabled, return, end
            obj.handle = EnsembleConnect;
            EnsembleDisconnect();
        end

        function force_home(obj,end_enabled)
            VariableDefault('end_enabled', false);
            % Performs naive homing on the Ensemble axes. Ignores current
            % position and calls the standard Ensemble home.
            %
            % :param axes: The axes on the Ensemble to home.
            obj.set_online(obj.all_axes, true);
            obj.handle = EnsembleConnect;
            axes = obj.target_axes(~isnan(obj.target_axes));
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , axes, obj.default_homeSetup);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            EnsembleMotionEnable(obj.handle, axes);
            
            EnsembleMotionHome(obj.handle, axes);
            EnsembleMotionWaitForMotionDone(obj.handle, axes, EnsembleWaitOption.MoveDone, 50000);   % Wait For Motion Done. timeout = 50000
            if ~end_enabled
                EnsembleMotionDisable(obj.handle, axes);
            end
            EnsembleDisconnect;
            obj.set_online(obj.all_axes, false);
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
        end

        function home(obj,end_enabled)
            VariableDefault('end_enabled', false);
            % HOME axes in the shortest path (to avoid wire twist)
            obj.set_online(obj.target_axes, true);
            obj.handle = EnsembleConnect;
            EnsemblePSOControl(obj.handle, obj.all_axes, EnsemblePsoMode.Reset);
            % Set the HOMEing direction according to CurrentPosition
            CurrentPosition = NaN([1,length(obj.all_axes)]);
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(1), obj.default_homeSetup);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(2), obj.default_homeSetup);
            CurrentPosition(1) = EnsembleStatusGetItem  (obj.handle, obj.all_axes(1), EnsembleStatusItem.PositionFeedback);   % Get Program Position Feedback (ID = 1) of central axis.
            CurrentPosition(2) = EnsembleStatusGetItem  (obj.handle, obj.all_axes(2), EnsembleStatusItem.PositionFeedback);   % Get Program Position Feedback (ID = 1) of outer axis.
            CurrentPosition = rad2deg(wrapToPi(deg2rad(CurrentPosition)));
            obj.homed(find(abs(CurrentPosition)<0.1)) = true;
            obj.homed(find(abs(CurrentPosition)>=0.1)) = false;
            if CurrentPosition(1)<0
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(1), 1);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            end
            if CurrentPosition(2)<0
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(2), 1);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            end
            

            % if already Homed, not to Home again
            axes = obj.target_axes;
            if isnan(axes(2)) || obj.homed(2)
                axes(2)=[];
            end
            if isnan(axes(1)) || obj.homed(1)
                axes(1)=[];
            end
            if isempty(axes)
                if ~end_enabled
                    EnsembleMotionDisable(obj.handle, obj.all_axes);
                end
                EnsembleDisconnect;
                obj.set_online(obj.target_axes, false);
                obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
                return
            end
            
            % Home
            EnsembleMotionEnable(obj.handle, axes);
            EnsembleMotionHome(obj.handle, axes);
            EnsembleMotionWaitForMotionDone(obj.handle, axes, EnsembleWaitOption.MoveDone, 50000);   % Wait For Motion Done. timeout = 50000
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(1), obj.default_homeSetup);    % Set HomeSetup Parameter (ID = 75). 0 = CCW/Negative Direction, 1 = CW/Positive Direction
            EnsembleParameterSetValue(obj.handle, EnsembleParameterId.HomeSetup , obj.all_axes(2), obj.default_homeSetup);
            if ~end_enabled
                EnsembleMotionDisable(obj.handle, obj.all_axes);
            end
            EnsembleDisconnect;
            obj.set_homed(obj.target_axes,true);
            obj.set_online(obj.target_axes, false);
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
        end

        function reset(obj)
            % function removed
        end

        function newFunction(obj)
            % something.
        end

        function offset_error = calibrate_zero(obj)
            % Measures the analog input voltage to the Ensemble controller.
            %
            % :param axes: The axes to monitor for the analog input
            % voltage.
            % :return: The average analog input over 100 samples.

            obj.handle = EnsembleConnect;
            axes = obj.target_axes(~isnan(obj.target_axes));
            gearmode = 1; % Specify 0 for OFF, 1 for ON without filter, and 2 for ON with filter.

            % Values
            vals = nan(1,100);

            % Set gear params
            for i=1:length(obj.all_axes)
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamSource, obj.all_axes(i), obj.gearcam_source);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamScaleFactor, obj.all_axes(i), 0);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamAnalogDeadband, obj.all_axes(i), 0);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GainKpos, obj.all_axes(i), 0);
            end
            
            % Enable
            EnsembleMotionEnable(obj.handle, axes);

            % Subtract offset on analog input
            

            % Set to gear mode
            for i=1:length(axes)
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.Analog0InputOffset, axes(i), obj.ai_offset(i));
                cmd = sprintf('GEAR @%i, %i', axes(i), gearmode);
                EnsembleCommandExecute(obj.handle, cmd);
            end
            
            for j=1:length(obj.all_axes)
                for i = 1:100
                    vals(1, i) = EnsembleIOAnalogInput(obj.handle, obj.all_axes(j), obj.ensemble_ai_channel(j));
                end
                offset_error(j) = mean(vals);
            end

            EnsembleMotionDisable(obj.handle, axes);
            
            gearmode = 0; % Specify 0 for OFF, 1 for ON without filter, and 2 for ON with filter.
            for i=1:length(obj.all_axes)
                % Reset gear parameters to their defaults
                cmd = sprintf('GEAR @%i, %i', obj.all_axes(i), gearmode);
                EnsembleCommandExecute(obj.handle, cmd); % Take stage out of gear mode
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamSource, obj.all_axes(i), obj.default_gearsource);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamScaleFactor, obj.all_axes(i), obj.default_gearscalefactor);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamAnalogDeadband, obj.all_axes(i), obj.default_analogdeadband);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GainKpos, obj.all_axes(i), obj.default_gainkpos(i));
            end

            EnsembleDisconnect();
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
        end

        function move_to(obj, pos, speed, end_enabled)
            % Moves rotation stage to a relative position with given speed.
            %
            % :param axes: The axes to move.
            % :param pos: The position relative from current position to
            % move.
            % :param speed: The speed of the movement.
            % :param end_enabled: Bool specifying whether axes should be
            % left enabled at the end of movement.

            if ~obj.enabled, return, end
            obj.set_online(obj.target_axes, true);

            % TODO - position check

            % TODO - speed check
            
            VariableDefault('speed', obj.default_speed);
            VariableDefault('end_enabled', false);
            obj.handle = EnsembleConnect;
            axes = obj.target_axes(~isnan(obj.target_axes));
            pos(:,find(isnan(pos))) = [];
            speed(:,find(isnan(speed))) = [];

            EnsembleMotionEnable(obj.handle, axes);
            % EnsembleMotionSetupIncremental(obj.handle);   % set motion mode to incremental move on axes
            EnsembleMotionSetupAbsolute(obj.handle);    % set motion mode to absolute move on axes
            
            EnsembleMotionLinear(obj.handle, axes, pos, speed);
            EnsembleMotionWaitForMotionDone(obj.handle, axes, EnsembleWaitOption.MoveDone, 50000);   % Wait For Motion Done. timeout = 50000
            obj.set_homed(obj.target_axes,false);

            % Stay enabled if requested
            if ~end_enabled
                EnsembleMotionDisable(obj.handle, axes)
            end
            EnsembleDisconnect();
            obj.set_online(obj.target_axes, false);
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
        end

        function sessionHandle = listen(obj)
            % Sets up the Ensemble axes to listen to an incoming voltage
            % signal to drive the stage in gear mode.
            %
            % :param axes: The axes to drive with analog input.
            % :return: A obj.handle to the active Ensemble session listening to
            % voltage input.

            obj.handle = EnsembleConnect;
            axes = obj.target_axes(~isnan(obj.target_axes));
            gearmode = 1; % Specify 0 for OFF, 1 for ON without filter, and 2 for ON with filter.
            % Setup analog output velocity tracking
            for i=1:length(obj.all_axes)
                EnsembleAdvancedAnalogTrack(obj.handle, obj.all_axes(i), obj.ensemble_ao_channel(i), ...
                    obj.ensemble_ao_servo_value, obj.ensemble_ao_scale_factor(i), 0);
                
                % Setup PSO output
                EnsemblePSOControl(obj.handle, obj.all_axes(i), EnsemblePsoMode.Reset);
                EnsemblePSOPulseCyclesAndDelay(obj.handle, obj.all_axes(i), 1000000, 500000, 0, 0);
                EnsemblePSOOutputPulse(obj.handle, obj.all_axes(i));
                
                % Setup gearing
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamSource, obj.all_axes(i), obj.gearcam_source);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamScaleFactor, obj.all_axes(i), obj.gear_scale(i));
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GearCamAnalogDeadband, obj.all_axes(i), obj.deadband);
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.GainKpos, obj.all_axes(i), 0);
            end
    
                % Enable motion
                EnsembleMotionEnable(obj.handle, axes);
                
            for i=1:length(axes)
                % Subtract offset on analog input
                EnsembleParameterSetValue(obj.handle, EnsembleParameterId.Analog0InputOffset, axes(i), obj.ai_offset(i));

                % Set to gear mode - TODO hard coded @0 for axis
                cmd = sprintf('GEAR @%i, %i', axes(i), gearmode);
                EnsembleCommandExecute(obj.handle, cmd);
            end
            sessionHandle = obj.handle;
        end

        function stop_listen(obj, sessionHandle, end_enabled)
            % If Ensemble is listening for voltage input, stop it and
            % reset.
            %
            % :param sessionHandle: Handle to the Ensemble session that is
            % listening for voltage input.
            % :param axes: The axes to halt listening on.
            VariableDefault('end_enabled', false);
            
            gearmode = 0; % Specify 0 for OFF, 1 for ON without filter, and 2 for ON with filter.

            for i=1:length(obj.all_axes)
                % Stay enabled if requested
                if ~end_enabled
                    EnsembleMotionDisable(sessionHandle, obj.all_axes(i));
                end
    
                % Pulse the digital output
                EnsemblePSOControl(sessionHandle, obj.all_axes(i), EnsemblePsoMode.Fire);
    
                % Reset gear parameters to their defaults
                cmd = sprintf('GEAR @%i, %i', obj.all_axes(i), gearmode);
                EnsembleCommandExecute(sessionHandle, cmd); % Take stage out of gear mode
                EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamSource, obj.all_axes(i), obj.default_gearsource);
                EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamScaleFactor, obj.all_axes(i), obj.default_gearscalefactor);
                EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GearCamAnalogDeadband, obj.all_axes(i), obj.default_analogdeadband);
                EnsembleParameterSetValue(sessionHandle, EnsembleParameterId.GainKpos, obj.all_axes(i), obj.default_gainkpos(i));
            end
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
            EnsembleDisconnect();
        end

        function reset_pso(obj)
            % Resets the Ensemble PSO.
            %
            % :param axes: The axes on which to reset PSO.

            obj.handle = EnsembleConnect;
            for i=1:length(obj.all_axes)
                EnsemblePSOControl(obj.handle, obj.all_axes(i), EnsemblePsoMode.Reset);
            end
            EnsembleDisconnect();
        end

        function stop(obj)
            % Stops active tasks and disables motion on the Ensemble.

            if ~obj.enabled, return, end
            obj.set_targetaxes(NaN([1,length(obj.all_axes)]));
            obj.abort_all();
        end

        function set_targetaxes(obj, axes)  
            % axes -- Central only = [0, NaN]. Outer only = [NaN, 1]. Both = [0, 1]. Neither = [NaN, NaN].
            obj.target_axes = axes;
        end

        function set_homed(obj, axes, logicallabel)
            obj.homed(~isnan(axes)) = logicallabel;
        end

        function set_online(obj, axes, logicallabel)
            obj.online(~isnan(axes)) = logicallabel;
        end
    end
end

