classdef Soloist < handle
    
    properties
        
        teensy_offset
        ni_offset
        v_per_cm_per_s
    end
    
    properties (SetAccess = private)
        
        max_limits
        homed = false;
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
        
        
            % directory in which the soloist commands are stored
            obj.dir = config.soloist.dir;
            
            % default speed at which we will move the soloist
            obj.default_speed = config.soloist.default_speed;
            
            % expected volts/cm/s on the analog input
            obj.v_per_cm_per_s = config.soloist.v_per_cm_per_s;
            
            % max limits of the stage... extra precautions
            obj.max_limits = config.stage.max_limits;
            
            % the amount of voltage offset expected on the analog input pin 
            % when listening to the teensy or NI
            % TODO: implement this...
            obj.teensy_offset = config.soloist.teensy_offset;
            obj.ni_offset = config.soloist.ni_offset;
            
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
        
            % run the abort command (this is in SoloistAbortProc)
            obj.h_abort.run();
            
            % clear all other running processes (if any)
            obj.proc_array.clear_all();
            
            % TODO: look for task errors here?
            obj.h_abort.restart();
        end
        
        
        
        function home(obj)
        %%HOME(obj)
        %   runs the HOME command for the soloist (see Soloist
        %   documentation), resets any parameters on the soloist to
        %   defaults and disables the stage.
        
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
        
        
        
        function proc = listen_until(obj, back_pos, forward_pos, source)
        %%proc = LISTEN_UNTIL(obj, back_pos, forward_pos, source)
        %   
        %   Puts the stage in 'gear' mode, which will make the soloist 
        %   listen to the analog input and convert a voltage to a velocity, 
        %   until one of the limits 'back_pos' or 'forward_pos' are reached 
        %   or an error condition occurs (at which point the process ends)
        %
        %   'source' indicates which voltage source will be listened to, and
        %   determines the voltage offset to apply to the analog input.
        %
        %   There are no defaults.
        %
        %       'back_pos' and 'forward_pos' must be numeric, not infinite or
        %       nan and between the limits set by Soloist.max_limits
        %       'forward_pos' must be < 'back_pos' (this is a feature of
        %       our stage in which forward is a lower numeric value than
        %       backwards.
        %
        %       'source' must be either 'teensy' or 'ni'
        
        
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
            
            % which source are we listening to
            % TODO: implement this!!
            if strcmp(source, 'teensy')
                offset = obj.teensy_offset;
            elseif strcmp(source, 'ni')
                offset = obj.ni_offset;
            else
                fprintf('unknown source of voltage input (either ''teensy'' or ''ni''');
                return
            end
            
            fname = obj.full_command('listen_until');
            cmd = sprintf('%s %i %i', fname, back_pos, forward_pos);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
    end
    
    
    methods (Access = private)
        
        function fname = full_command(obj, cmd)
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end