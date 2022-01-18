classdef Soloist < handle
% Soloist Class for handling commands to the Soloist stage controller
%
%   Soloist Properties:
%       deadband_scale      - multiply the value of the deadband in the
%                             config structure by this value to determine
%                             the deadband
%       deadband            - the value of the deadband to send to the
%                             controller (in Volts)
%       ai_offset           - offset in mV to add to the controller when
%                             going into gear mode (see below)
%       max_limits          - position limits of the stage (in controller
%                             units, usually mm, but perhaps this can
%                             change?)
%       homed               - whether the stage has been homed
%       offset_limits       - limits of the `ai_offset` property
%       gear_scale          - value of GearCamScaleFactor to apply on the
%                             controller when in gear mode
%       deadband_limits     - limits of the `deadband` property
%       v_per_cm_per_s      - volts per cm/s (determined by the Teensy actually?)
%       dir                 - directory containing the executable files
%                             carrying out the Soloist commands
%       proc_array          - object of class ProcArray
%       h_abort             - handle to the process controlling rapid
%                             aborting of the currently executing Soloist
%                             command  
%       default_speed       - default speed to move the stage
%
%   Soloist Methods:
%       delete              - destructor for this class
%       abort               - aborts all tasks and resets all parameters on
%                             the soloist 
%       stop                - disables the axis, resets the stage and stops
%                             all the processes.
%       reset_pso           - resets the PSO on the controller
%       communicate         - communicates and resets the connection with
%                             the Soloist controller 
%       home                - homes the linear stage
%       reset               - resets the linear stage to default position
%                             and parameters 
%       move_to             - moves the linear stage to a position
%       calibrate_zero      - measures the analog input voltage to the
%                             Soloist controller. 
%       listen_until            - sends stage into gear mode to listen to
%                                 the analog input (WARNING!) 
%       mismatch_ramp_down_at   - sends stage into gear mode to listen to
%                                 the analog input (WARNING!) 
%       mismatch_ramp_up_until  - sends stage into gear mode to listen to
%                                 the analog input (WARNING!) 
%       set_offset          - set the `ai_offset` property
%       set_gear_scale      - set the `gear_scale` property
%       set_deadband        - set the `deadband` property
%       full_command        - create a full path to the executables
%
%   TODO: `ai_offset` and `deadband` should be private properties (may
%         affect Trial classes)

    properties    
        
        enabled
        deadband_scale = 0.2
        deadband
        ai_offset
    end
    
    properties (SetAccess = private)
        
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
        % Soloist
        %
        %   Soloist(CONFIG) creates object for interfacing with the Soloist
        %   controller via separate, standalone executable programs stored
        %   in the direcotry `config.soloist.dir`. CONFIG is the
        %   configuration structure.
        
            obj.enabled = config.soloist.enable;
            if ~obj.enabled, return, end
            
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
        %%delete Main object destructor
            
            % make sure the Soloist parameters are reset, it is disabled
            % and all processes are deleted
            obj.abort()
        end
        
        
        
        function abort(obj)
        %%abort Aborts all tasks and resets all parameters on the soloist
        %
        %   abort() Sends 'abort' signal to the abort.exe program
        %
        %   See also README in Soloist directory and `abort.c` file.
        
            if ~obj.enabled, return, end
            
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('abort');
            
            % clear all other running processes (if any)
            obj.proc_array.clear_all();
            
            % TODO: look for task errors here?
            obj.h_abort.restart();
        end
        
        
        
        function stop(obj)
        %%stop Disables the axis, resets the stage and stops all the
        %%processes. 
        %
        %   stop() sends 'reset_pso' and 'stop' signals to the abort.exe
        %   program.
        %
        %   See also README in Soloist directory and `abort.c` file.
            
            if ~obj.enabled, return, end
            
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
        %%reset_pso Resets the PSO on the controller.
        %
        %   reset_pso() sends 'reset_pso' signal to the abort.exe program. 
        %
        %   See also README in Soloist directory and `abort.c` file.
        
            if ~obj.enabled, return, end
            
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run('reset_pso');
        end
        
        
        function proc = communicate(obj)
        %%communicate Communicates and resets the connection with the
        %%Soloist controller
        %
        %   communicate() runs the communicate.exe program
        %
        %   See also README in Soloist directory and `communicate.c` file.
        
            if ~obj.enabled, return, end
            
            cmd = obj.full_command('communicate');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function home(obj)
        %%home Homes the linear stage
        %
        %   home() runs the home.exe program. Also resets any parameters on
        %   the Soloist to defaults and disables the stage.
        %
        %   See also README in Soloist directory and `home.c` file. 
        
            if ~obj.enabled, return, end
            
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
        %%reset Resets the linear stage to default position and parameters 
        %
        %   reset() runs the reset.exe program. Moves the linear stage to a
        %   default position and also resets any parameters on the Soloist
        %   to defaults and disables the stage.
        %
        %   See also README in Soloist directory and `reset.c` file.
        
            if ~obj.enabled, return, end
            
            cmd = obj.full_command('reset');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        
        function proc = move_to(obj, pos, speed, end_enabled)
        %%move_to Moves the linear stage to a position
        %
        %   PROCESS = move_to(POSITION, SPEED, LEAVE_ENABLED) 
        %   runs the move_to.exe program. This moves the linear stage to
        %   the position POSITION (units are in Soloist controller units,
        %   which for us has always been mm), at speed SPEED (also units in
        %   controller units, for us this has been mm/s). LEAVE_ENABLED is
        %   a logical, true or false, and determines whether to leave the
        %   stage enabled after the move has been made (true) or disable
        %   the stage after the move (false).
        %
        %   POSITION must be within the limits specified by the
        %   `max_limits` property. SPEED must be between 10 and 500 (hard
        %   coded values).
        %
        %   The handle to the process is returned in PROCESS.
        %
        %   TODO: make speed limits optional?
        %
        %   See also README in Soloist directory and `move_to.c` file.
        
            % set defaults
            VariableDefault('speed', obj.default_speed);
            VariableDefault('end_enabled', false);
            
            if ~obj.enabled, return, end
            
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
        %%calibrate_zero Measures the analog input voltage to the Soloist
        %%controller.
        %
        %   WARNING: if GEAR_OFF is false (the default), the stage goes
        %   into gear mode and thus may move suddenly and unexpectedly.
        %
        %   RESIDUAL_OFFSET_MV = calibrate_zero(BACKWARD_POSITION, FORWARD_POSITION, AI_OFFSET, GEAR_OFF, LEAVE_ENABLED)
        %   runs the calibrate_zero.exe or calibrate_zero_no_gear.exe
        %   programs. BACKWARD_POSITION and FORWARD_POSITION determine the
        %   limits which if the stage moves beyond them the executable will
        %   stop (must be in Soloist controller units, e.g. mm, and within
        %   the bounds specified by `max_limits` property. AI_OFFSET is the
        %   offset in millivolts to apply before taking the measurement (i.e. output of
        %   this function will be *relative* to this value). GEAR_OFF
        %   should be a boolean, true or false, and determines whether to
        %   take the measurement in gear mode (false, default) or not in
        %   gear mode (true). LEAVE_ENABLED is a logical, true or false,
        %   and determines whether to leave the stage enabled after the
        %   measurement has been made (true) or disable the stage after the
        %   measurement (false). 
        %
        %   FORWARD_POSITION must be < BACKWARD_POSITION.
        %
        %   The residual analog input voltage on the controller is returned
        %   in RESIDUAL_OFFSET_MV, in millivolts. This value is relative to
        %   the AI_OFFSET value.
        %
        %   See also README in Soloist directory and `calibrate_zero.c` file.
        
            if ~obj.enabled; return; end
            
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
        
        
        
        function proc = listen_until(obj, back_pos, forward_pos, wait_for_trigger)
        %%listen_until Couples the voltage input to the Soloist controller
        %%to the velocity of the linear stage.
        %
        %   WARNING: the stage goes into gear mode and thus may move
        %   suddenly and unexpectedly. 
        %
        %   PROCESS = listen_until(BACKWARD_POSITION, FORWARD_POSITION, WAIT_FOR_TRIGGER)
        %   runs the listen_until.exe. BACKWARD_POSITION and
        %   FORWARD_POSITION determine the limits which if the stage moves
        %   beyond them the executable will stop (must be in Soloist
        %   controller units, e.g. mm, and within the bounds specified by
        %   `max_limits` property.
        %
        %   FORWARD_POSITION must be < BACKWARD_POSITION.
        %
        %   WAIT_FOR_TRIGGER is optional, and can be a boolean which
        %   determines whether the Soloist waits for a trigger before going
        %   into gear mode and listening to the voltage input. The default
        %   is true, wait for a trigger.
        %
        %   The handle to the process is returned in PROCESS.
        %
        %   See also README in Soloist directory and `listen_until.c` file.
        
            if ~obj.enabled, return, end
            
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
        %%mismatch_ramp_down_at Couples the voltage input to the Soloist controller
        %%to the velocity of the linear stage until a position is reached
        %%when the gain between voltage and velocity is ramped down to
        %%zero.
        %
        %   WARNING: the stage goes into gear mode and thus may move
        %   suddenly and unexpectedly. 
        %
        %   PROCESS = mismatch_ramp_down_at(BACKWARD_POSITION, FORWARD_POSITION)
        %   runs the mismatch_ramp_down_at.exe. BACKWARD_POSITION and
        %   FORWARD_POSITION determine the limits which if the stage moves
        %   beyond them the executable will stop (must be in Soloist
        %   controller units, e.g. mm, and within the bounds specified by
        %   `max_limits` property.
        %
        %   FORWARD_POSITION must be < BACKWARD_POSITION.
        %
        %   The handle to the process is returned in PROCESS.
        %
        %   See also README in Soloist directory and `mismatch_ramp_down_at.c` file.
        
            if ~obj.enabled, return, end

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
        %%mismatch_ramp_up_until After a trigger is received couples the
        %%voltage input to the Soloist controller to the velocity of the
        %%linear stage until a position is reached. 
        %
        %   WARNING: the stage goes into gear mode and thus may move
        %   suddenly and unexpectedly. 
        %
        %   PROCESS = mismatch_ramp_up_until(BACKWARD_POSITION, FORWARD_POSITION)
        %   runs the mismatch_ramp_up_until.exe. BACKWARD_POSITION and
        %   FORWARD_POSITION determine the limits which if the stage moves
        %   beyond them the executable will stop (must be in Soloist
        %   controller units, e.g. mm, and within the bounds specified by
        %   `max_limits` property. FORWARD_POSITION must be < BACKWARD_POSITION.
        %
        %   The handle to the process is returned in PROCESS.
        %
        %   Waits for a trigger to be received and then ramps up the gain
        %   between voltage and velocity from zero to a nominal value
        %   (defined in ramp_up_gain.ab).
        %
        %   See also README in Soloist directory and `mismatch_ramp_up_until.c` file.
        
            if ~obj.enabled, return, end
        
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
        %%set_offset Set the `ai_offset` property
        %
        %   set_offset(VALUE) sets the `ai_offset` value to VALUE which
        %   must be between the limits defined in `offset_limits` property.
        
            if ~obj.enabled, return, end
            
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
        %%set_gear_scale Set the `gear_scale` property
        %
        %   set_gear_scale(VALUE) sets the `gear_scale` value to VALUE.
           
            if ~obj.enabled, return, end
            
            % check that the value is in allowable range
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'set_gear_scale');
                return
            end
            
            obj.gear_scale = val;
        end
        
        
        
        function set_deadband(obj, val)
        %%set_deadband Set the `ai_offset` property
        %
        %   set_deadband(VALUE) sets the `deadband` value to VALUE which
        %   must be between the limits defined in `deadband_limits` property.
        
            if ~obj.enabled, return, end
            
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
        %%full_command Create a full path to the executables
        %
        %   FULLFILE = full_command(COMMAND) creates a full path from a
        %   command string COMMAND.
        
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end
