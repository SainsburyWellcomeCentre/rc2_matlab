classdef Soloist < handle
    % Soloist class for handling commands to the Soloist stage controller.

    properties    
        deadband_scale = 0.2 % Scaling coefficient for deadband value in main configuration structure to calculate deadband.
        deadband % The value (in volts) of the deadband to send to the controller.
        ai_offset % offset in mV to add to the controller when entering gear mode.
    end
    
    properties (SetAccess = private)
        max_limits % Position limits of the stage (in controller units, usually mm).
        homed = false; % Boolean representing whether the stage is homed.
        offset_limits = [-1000, 1000]; % Limits of the :attr:`ai_offset` property.
        gear_scale % Value of GearCamScaleFactor to apply on the controller when in gear mode.
        deadband_limits = [0, 1]; % Limits of the :attr:`deadband` property.
        v_per_cm_per_s % Volts per cm/s (actually determined by Teensy) - NOTE AE confirm.
    end
    
    properties (SetAccess = private, Hidden = true)
        dir % Directory containing the executable files carrying out the Soloist commands.
        proc_array % :class:`rc.aux_.ProcArray`
        h_abort % Handle to the process controlling rapid aborting of the currently executing Soloist command.
        default_speed % Default speed to move the stage.
    end
    
    
    methods
        function obj = Soloist(config)
            % Constructor for a :class:`rc.dev.Soloist` device.
            % Interfaces with the Soloist controller via separate, 
            % standalone executable programs stored in the directory `config.soloist.dir`.
            %
            % :param config: The main configuration structure.
        
            % directory in which the soloist commands are stored
            obj.dir = config.soloist.dir;
            
            % default speed at which we will move the soloist
            obj.default_speed = config.soloist.default_speed;
            
            % max limits of the stage... extra precautions
            obj.max_limits = config.stage.max_limits;
            
            % the amount of voltage offset expected on the analog input pin 
            % when listening to the teensy or NI
            obj.ai_offset = config.soloist.ai_offset;
            obj.gear_scale = config.soloist.gear_scale;
            obj.deadband = obj.deadband_scale * config.soloist.deadband;
            obj.v_per_cm_per_s = config.soloist.v_per_cm_per_s;
            
            % we setup a separate process dedicated to aborting the current command
            % on the soloist... it runs constantly and is always connected to the
            % soloist (otherwise, connecting would take about 2s... to slow for an
            % abort operation).
            % ideally all other commands to the soloist (home, listen_to, etc.) would 
            % also be immediate (and not run as separate executables... 
            % but that requires more sophisticated programming...)
            abort_cmd = obj.full_command('abort');
            obj.h_abort = SoloistAbortProc(abort_cmd);
            
            % object for storing any processes created to interact with the
            % soloist... we can kill them all
            obj.proc_array = ProcArray();
        end
        
        
        function delete(obj)
            % Destructor for :class:`rc.dev.Soloist` device.

            obj.abort()
        end
        
        
        function abort(obj)
            % Aborts all tasks and resets all parameters on the soloist.
            % Sends 'abort' signal to the abort.exe program. NOTE AE - reference to c file.
        
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('abort');
            
            % clear all other running processes (if any)
            obj.proc_array.clear_all();
            
            % TODO: look for task errors here?
            obj.h_abort.restart();
        end
        
        
        function stop(obj)
            % Disbles the axis, resets the stage and stops all current processes.
            % Sends 'reset_pso' and 'stop' signals to the abort.exe program. NOTE AE - reference to c file.
        
            % make sure PSO is reset
            obj.h_abort.run('reset_pso');
            
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('stop');
            
            % clear all other running processes (if any)
            obj.proc_array.clear_all();
            
            % TODO: look for task errors here?
            obj.h_abort.restart();
        end
        
        
        function reset_pso(obj)
            % Reset the PSO on the Soloist controller.
            % Sends 'reset_pso' signal to the abort.exe program.
        
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('reset_pso');
        end
        
        
        function proc = communicate(obj)
            % Communicates and resets the connection with the Soloist controller.
            %
            % :return: :class:`rc.aux_.ProcHandler` object, handle to the process.
        
            cmd = obj.full_command('communicate');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function home(obj)
            % Homes the linear stage.
            % Runs the home.exe program and resets any parameters on the Soloist to defaults. Disables the stage. 
        
            cmd = obj.full_command('home');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
            
            obj.homed = true;
        end
        
        
        
        function reset(obj)
            % Resets the linear stage to the default position and parameters.
            % Runs the reset.exe program.
        
            cmd = obj.full_command('reset');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function proc = move_to(obj, pos, speed, end_enabled)
            % Moves the linear stage to a position with given speed.
            % Uses the move_to.exe program.
            %
            % :param pos: The position to move to in Soloist controller units (usually mm). Must be within the limits specified by the :attr:`max_limits` property.
            % :param speed: The speed to move in Soloist controller units (usually mm/s). Must be within 10 and 500 (hard-coded values).
            % :param end_enabled: Boolean specifying whether to leave the stage enabled (true) or disabled (false) after the move. 
            % :return: :class:`rc.aux_.ProcHandler` object, handle to the process.
        
            % set defaults
            VariableDefault('speed', obj.default_speed);
            VariableDefault('end_enabled', false);
            
            % check position
            if ~isnumeric(pos) || isinf(pos) || isnan(pos)
                fprintf('%s: %s ''pos'' must be numeric\n', class(obj), 'move_to');
                return
            end
            if pos > obj.max_limits(1) || pos < obj.max_limits(2)
                fprintf('%s: %s pos must be between %.1f and %.1f\n', ...
                    class(obj), 'move_to', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check speed
            if ~isnumeric(speed) || isinf(speed) || isnan(speed)
                fprintf('%s: %s ''speed'' must be numeric\n', class(obj), 'move_to');
                return
            end
            if speed > 500 || speed < 10
                fprintf('%s: %s speed must be between 10 and 500\n', class(obj), 'move_to');
                return
            end
            
            if ~islogical(end_enabled)
                fprintf('%s: %s ''end_enabled'' must be boolean\n', class(obj), 'move_to');
                return
            end
            
            % convert to logical
            end_enabled = logical(end_enabled);
            
            fname = obj.full_command('move_to');
            cmd = sprintf('%s %i %i %i', fname, pos, speed, end_enabled);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function average_offset_mV = calibrate_zero(obj, back_pos, forward_pos, offset, no_gear, leave_enabled)
            % Measures the analog input voltage to the Soloist and runs the calibrate_zero.exe or calibrate_zero_no_gear.exe programs.
            %
            % WARNING: ``no_gear`` is false (the default), the stage goes into gear mode and thus may move suddenly and unexpectedly.
            %
            % :param back_pos: Limit of the backward position. If stage moves beyond limit the executable will stop. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param forward_pos: Limit of the forward position. If stage moves beyond limit the executable will stop. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param offset: Offset in millivolts to apply before taking the output measurement (output of this function will be relative to this value).
            % :param no_gear: Boolean specifying whether to take the measurement in gear mode (false, default) or not in gear mode (true).
            % :param leave_enabled: Boolean specifying whether to leave the stage enabled after the measurement has been made (true) or disable the stage after measurement (false).
            % :return: The residual analog input voltage on the controller relative to ``offset``
            %
            % ``forward_pos`` must be < ``back_pos``
        
            VariableDefault('no_gear', false);
            VariableDefault('leave_enabled', false)
        
            % check 'back_pos'
            if ~isnumeric(back_pos) || isinf(back_pos) || isnan(back_pos)
                fprintf('%s: %s ''back_pos'' must be numeric\n', class(obj), 'calibrate_zero');
                return
            end
            if back_pos > obj.max_limits(1) || back_pos < obj.max_limits(2)
                fprintf('%s: %s ''back_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'calibrate_zero', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check 'forward_pos'
            if ~isnumeric(forward_pos) || isinf(forward_pos) || isnan(forward_pos)
                fprintf('%s: %s ''forward_pos'' must be numeric\n', class(obj), 'calibrate_zero');
                return
            end
            if forward_pos > obj.max_limits(1) || forward_pos < obj.max_limits(2)
                fprintf('%s: %s ''forward_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'calibrate_zero', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check 'offset'
            if ~isnumeric(offset) || isinf(offset) || isnan(offset)
                fprintf('%s: %s ''offset'' must be numeric\n', class(obj), 'calibrate_zero');
                return
            end
            if offset > max(obj.offset_limits) || offset < min(obj.offset_limits)
                fprintf('%s: %s ''offset'' must be between %.2f and %.2f\n', ...
                    class(obj), 'calibrate_zero', min(obj.offset_limits), max(obj.offset_limits));
                return
            end
            
            % make sure forward and backwards are sensible way round
            if forward_pos > back_pos
                fprintf('%s: %s ''forward_pos'' must be > ''back_pos''\n', ...
                    class(obj), 'calibrate_zero');
                return
            end
            
            if no_gear
                fname = obj.full_command('calibrate_zero_no_gear');
                cmd = sprintf('%s %i %i %.8f %i', fname, back_pos, forward_pos, offset);
            else
                fname = obj.full_command('calibrate_zero');
                cmd = sprintf('%s %i %i %.8f %i', fname, back_pos, forward_pos, offset, leave_enabled);
            end
            
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
            
            % open up pipes to the process
            reader = p_java.getInputStream();
            
            % give it 60s to complete
            tic;
            while reader.available() == 0
                if toc > 60
                    fprintf('no return signal from calibrate_zero\n');
                    return
                end
            end
            
            fprintf('reading...');
            ret = [];
            for i = 1 : reader.available()
                ret(i) = reader.read();
            end
            
            str = char(ret);
            fprintf('%s...', str);
            
            % return value is in V, convert to mV
            average_offset_mV = str2double(str)*1e3;
        end
        
        function proc = listen_position(obj, back_pos, forward_pos, wait_for_trigger)
            fname = obj.full_command('listen_position');
            cmd = sprintf('%s %i %i %.8f %.8f %.8f %i', fname, back_pos, forward_pos, obj.ai_offset, obj.gear_scale, obj.deadband, wait_for_trigger);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        function proc = listen_until(obj, back_pos, forward_pos, wait_for_trigger)
            % Couples the voltage input to the Soloist controller. Uses the listen_until.exe program.
            % WARNING: the stage goes into gear mode and thus may move unexpectedly.
            % 
            % :param back_pos: Limit of the backward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param forward_pos: Limit of the forward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param wait_for_trigger: Optional boolean (default true) specifying whether Soloist should wait for trigger before going into gear mode and listening to the voltage input.
            % :return: :class:`rc.aux_.ProcHandler` object, handle to the process.
            %
            % ``forward_pos`` must be < ``back_pos``
        
            VariableDefault('wait_for_trigger', true);
        
            % check 'back_pos'
            if ~isnumeric(back_pos) || isinf(back_pos) || isnan(back_pos)
                fprintf('%s: %s ''back_pos'' must be numeric\n', class(obj), 'listen_until');
                return
            end
            if back_pos > obj.max_limits(1) || back_pos < obj.max_limits(2)
                fprintf('%s: %s ''back_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'listen_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check 'forward_pos'
            if ~isnumeric(forward_pos) || isinf(forward_pos) || isnan(forward_pos)
                fprintf('%s: %s ''forward_pos'' must be numeric\n', class(obj), 'listen_until');
                return
            end
            if forward_pos > obj.max_limits(1) || forward_pos < obj.max_limits(2)
                fprintf('%s: %s ''forward_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'listen_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % make sure forward and backwards are sensible way round
            if forward_pos > back_pos
                fprintf('%s: %s ''forward_pos'' must be > ''back_pos''\n', ...
                    class(obj), 'listen_until');
                return
            end
            
            fname = obj.full_command('listen_until');
            cmd = sprintf('%s %i %i %.8f %.8f %.8f %i', fname, back_pos, forward_pos, obj.ai_offset, obj.gear_scale, obj.deadband, wait_for_trigger);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function proc = mismatch_ramp_down_at(obj, back_pos, forward_pos)
            % Couples the voltage input to the Soloist controller to the velocity of the linear stage until a position is reached
            % when the gain between voltage and velocity is ramped down to zero.
            % Uses the mismatch_ramp_down_at.exe program.
            %
            % :param back_pos: Limit of the backward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param forward_pos: Limit of the forward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :return: :class:`rc.aux_.ProcHandler` object, handle to the process.
            %
            % ``forward_pos`` must be < ``back_pos``
        
            % check 'back_pos'
            if ~isnumeric(back_pos) || isinf(back_pos) || isnan(back_pos)
                fprintf('%s: %s ''back_pos'' must be numeric\n', class(obj), 'mismatch_ramp_down_at');
                return
            end
            if back_pos > obj.max_limits(1) || back_pos < obj.max_limits(2)
                fprintf('%s: %s ''back_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'mismatch_ramp_down_at', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check 'forward_pos'
            if ~isnumeric(forward_pos) || isinf(forward_pos) || isnan(forward_pos)
                fprintf('%s: %s ''forward_pos'' must be numeric\n', class(obj), 'mismatch_ramp_down_at');
                return
            end
            if forward_pos > obj.max_limits(1) || forward_pos < obj.max_limits(2)
                fprintf('%s: %s ''forward_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'mismatch_ramp_down_at', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % make sure forward and backwards are sensible way round
            if forward_pos > back_pos
                fprintf('%s: %s ''forward_pos'' must be > ''back_pos''\n', ...
                    class(obj), 'mismatch_ramp_down_at');
                return
            end
            
            fname = obj.full_command('mismatch_ramp_down_at');
            cmd = sprintf('%s %i %i %.8f %.8f %.8f', fname, back_pos, forward_pos, obj.ai_offset, obj.gear_scale, obj.deadband);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function proc = mismatch_ramp_up_until(obj, back_pos, forward_pos)
            % After a trigger is received couples the voltage input to the Soloist controller to the velocity of the linear stage until a position is reached.
            % WARNING: The stage goes into gear mode and this may move suddenly and unexpectedly.
            % Uses the mismatch_ramp_down_at.exe program.
            %
            % :param back_pos: Limit of the backward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :param forward_pos: Limit of the forward position. Should be in soloist controller units and within the bounds specified by :attr:`max_limits`.
            % :return: :class:`rc.aux_.ProcHandler` object, handle to the process.
            %
            % ``forward_pos`` must be < ``back_pos``
        
            % check 'back_pos'
            if ~isnumeric(back_pos) || isinf(back_pos) || isnan(back_pos)
                fprintf('%s: %s ''back_pos'' must be numeric\n', class(obj), 'mismatch_ramp_up_until');
                return
            end
            if back_pos > obj.max_limits(1) || back_pos < obj.max_limits(2)
                fprintf('%s: %s ''back_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'mismatch_ramp_up_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % check 'forward_pos'
            if ~isnumeric(forward_pos) || isinf(forward_pos) || isnan(forward_pos)
                fprintf('%s: %s ''forward_pos'' must be numeric\n', class(obj), 'mismatch_ramp_up_until');
                return
            end
            if forward_pos > obj.max_limits(1) || forward_pos < obj.max_limits(2)
                fprintf('%s: %s ''forward_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'mismatch_ramp_up_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            % make sure forward and backwards are sensible way round
            if forward_pos > back_pos
                fprintf('%s: %s ''forward_pos'' must be > ''back_pos''\n', ...
                    class(obj), 'mismatch_ramp_up_until');
                return
            end
            
            fname = obj.full_command('mismatch_ramp_up_until');
            cmd = sprintf('%s %i %i %.8f %.8f %.8f', fname, back_pos, forward_pos, obj.ai_offset, obj.gear_scale, obj.deadband);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function set_offset(obj, val)
            % Sets the :attr:`ai_offset` property.
            %
            % :param val: Value to set, must be within the limits defined in the :attr:`offset_limits` property.
        
            % check that the value is in allowable range
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'set_offset');
                return
            end
            if val > max(obj.offset_limits) || val < min(obj.offset_limits)
                fprintf('%s: %s ''val'' must be between %.1f and %.1f\n', ...
                    class(obj), 'set_offset', min(obj.offset_limits), max(obj.offset_limits));
                return
            end
            
            obj.ai_offset = val;
        end
        
        
        function set_gear_scale(obj, val)
            % Sets the :attr:`gear_scale` property.
            %
            % :param val: Value to set.
           
            % check that the value is in allowable range
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'set_gear_scale');
                return
            end
            
            obj.gear_scale = val;
        end
        
        
        function set_deadband(obj, val)
            % Set the :attr: `deadband` property.
            %
            % :param val: Value to set, must be within the :attr:`deadband_limits` property.
        
            % check that the value is in allowable range
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'set_deadband');
                return
            end
            if val > max(obj.deadband_limits) || val < min(obj.deadband_limits)
                fprintf('%s: %s ''val'' must be between %.1f and %.1f\n', ...
                    class(obj), 'set_deadband', min(obj.deadband_limits), max(obj.deadband_limits));
                return
            end
            
            obj.deadband = val;
        end
    end
    
    
    methods (Access = private)
        function fname = full_command(obj, cmd)
            % Creates a full path from a command string.
            %
            % :param cmd: Command string.
            % :return: Full path.
            %%full_command Create a full path to the executables
            %
            %   FULLFILE = full_command(COMMAND) creates a full path from a
            %   command string COMMAND.
        
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end
