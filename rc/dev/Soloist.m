classdef Soloist < handle
    
    properties    
        deadband_scale = 0.2
        deadband
        ai_offset
    end
    
    properties (SetAccess = private)
        
        enabled
        max_limits
        homed = false;
        offset_limits = [-1000, 1000];
        gear_scale
        deadband_limits = [0, 1];
        v_per_cm_per_s
    end
    
    properties (SetAccess = private, Hidden = true)
        
        dir
        proc_array
        h_abort
        default_speed
    end
    
    
    
    methods
        
        function obj = Soloist(config)
        %%obj = SOLOIST(config)
        %   Class for interfacing with the Soloist controller via separate,
        %   standalone executable programs stored in config.soloist.dir.
        %   
        %   
        %       config - configuration structure
        
            % is stage enabled?
            obj.enabled = config.stage.enabled;
        
            % if stage not enabled, set homed to true
            if ~obj.enabled
                obj.homed = true;
                return;
            end
            
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
        % main object destructor
            
            % make sure the Soloist parameters are reset, it is disabled
            % and all processes are deleted
            obj.abort()
        end
        
        
        
        function abort(obj)
        %%ABORT(obj)
        %   aborts all tasks and resets all parameters on the soloist
        
            if ~obj.enabled; return; end
        
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('abort');
            
            % clear all other running processes (if any)
            obj.proc_array.clear_all();
            
            % TODO: look for task errors here?
            obj.h_abort.restart();
        end
        
        
        
        function stop(obj)
        %%STOP(obj)
        %   disables the axis, resets the stage and stops all the
        %   processes.
            
            if ~obj.enabled; return; end
        
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
            
            if ~obj.enabled; return; end
            
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('reset_pso');
        end
        
        
        function proc = communicate(obj)
        %%COMMUNICATE(obj)
        %   communicates and resets the connection
        
            if ~obj.enabled; return; end
        
            cmd = obj.full_command('communicate');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function home(obj)
        %%HOME(obj)
        %   runs the HOME command for the soloist (see Soloist
        %   documentation), resets any parameters on the soloist to
        %   defaults and disables the stage.
        
            if ~obj.enabled; return; end
        
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
        %%RESET(obj)
        %   moves the soloist to a fixed "reset" position, resets any
        %   parameters on the soloist to defaults and disables the stage.
        
            if ~obj.enabled; return; end
            
            cmd = obj.full_command('reset');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function proc = move_to(obj, pos, speed, end_enabled)
        %%proc = MOVE_TO(obj, pos, speed, end_enabled)
        %   moves the stage to 'pos' position at speed 'speed'. if
        %   'end_enabled is true, the stage won't be disabled at the end,
        %   otherwise it will be disabled.
        %       defaults:   'speed':  Soloist.default_speed
        %                   'end_enabled': false
        %   pos must be     numeric, not infinite or nan
        %                   between limits set by Soloist.max_limits
        %   speed must be   numeric, not infinite or nan
        %                   between [10 and 500] (mm/s)
        %   end_enabled must be logical
        
            if ~obj.enabled; return; end
        
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
        
        
        function average_offset_mV = calibrate_zero(obj, back_pos, forward_pos, offset, no_gear)
        %%proc = calibrate_zero(obj, back_pos, forward_pos, offset, no_gear)
        %   
        %   Runs a calibration routine to determine the correct voltage
        %   offset to subtract to be stationary when the treadmill is not
        %   moving.
        %   
        %   back_pos and forward_pos are the positions of the stage at
        %   which the calibration routine will terminate (if it doesn't
        %   naturally terminate).
        %
        %   'offset' indicates the inital voltage offset to try.
        %
        %   'no_gear', if true run without gear mode
        
            if ~obj.enabled; return; end
            
            VariableDefault('no_gear', false);
        
        
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
            else
                fname = obj.full_command('calibrate_zero');
            end
            cmd = sprintf('%s %i %i %.8f', fname, back_pos, forward_pos, offset);
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
        
        
        
        
        function proc = listen_until(obj, back_pos, forward_pos, wait_for_trigger)
        %%proc = LISTEN_UNTIL(obj, back_pos, forward_pos)
        %   
        %   Puts the stage in 'gear' mode, which will make the soloist 
        %   listen to the analog input and convert a voltage to a velocity, 
        %   until one of the limits 'back_pos' or 'forward_pos' are reached 
        %   or an error condition occurs (at which point the process ends)
        %
        %       'back_pos' and 'forward_pos' must be numeric, not infinite or
        %       nan and between the limits set by Soloist.max_limits
        %       'forward_pos' must be < 'back_pos' (this is a feature of
        %       our stage in which forward is a lower numeric value than
        %       backwards.
        %       'wait_for_trigger' is true unless specified (determines
        %       whether the soloist waits for a trigger to go low
        
            if ~obj.enabled; return; end
        
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
        %%proc = MISMATCH(obj, back_pos, forward_pos)
        %   
        %   Puts the 
        
            if ~obj.enabled; return; end
        
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
        %%proc = MISMATCH_RAMP_UP_UNTIL(obj, back_pos, forward_pos)
        %   
        
            if ~obj.enabled; return; end
        
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
            
            if ~obj.enabled; return; end
            
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
            
            if ~obj.enabled; return; end
            
            % check that the value is in allowable range
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'set_gear_scale');
                return
            end
            
            obj.gear_scale = val;
        end
        
        
        function set_deadband(obj, val)
            
            if ~obj.enabled; return; end
            
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
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end