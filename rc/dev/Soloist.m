classdef Soloist < handle
    
    properties
        proc_array
        h_abort
        dir
        max_limits
        teensy_offset
        ni_offset
    end
    
    properties (SetAccess = private, Hidden = true)
        default_speed
    end
    
    
    
    methods
        
        function obj = Soloist(config)
            
            % directory in which the soloist commands
            obj.dir = config.soloist.dir;
            
            % default speed at which we will move the soloist
            obj.default_speed = config.soloist.default_speed;
            obj.teensy_offset = config.soloist.teensy_offset;
            obj.ni_offset = config.soloist.ni_offset;
            cmd = obj.full_command('abort');
            obj.h_abort = SoloistAbortProc(cmd);
            obj.proc_array = ProcArray();
            obj.max_limits = config.stage.max_limits;
        end
        
        
        function abort(obj)
            obj.h_abort.run();
            obj.proc_array.clear_all();
            % look for task errors here?
        end
        
        
        function home(obj)
            cmd = obj.full_command('home');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function disable(obj)
            cmd = obj.full_command('disable_');
            disp(cmd)
%             % start running the process
%             runtime = java.lang.Runtime.getRuntime();
%             proc = runtime.exec(cmd);
        end

        
        function enable(obj)
            cmd = obj.full_command('enable_');
            disp(cmd)
%             % start running the process
%             runtime = java.lang.Runtime.getRuntime();
%             proc = runtime.exec(cmd);
        end
        
        
        function reset(obj)
            cmd = obj.full_command('reset');
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function proc = move_to(obj, pos, speed, end_enabled)
            
            VariableDefault('speed', obj.default_speed);
            VariableDefault('end_enabled', false);
            
            % checks go here!
            if ~isnumeric(pos) || isinf(pos) || isnan(pos)
                fprintf('%s: %s ''pos'' must be numeric\n', class(obj), 'move_to');
                return
            end
            if pos > obj.max_limits(1) || pos < obj.max_limits(2)
                fprintf('%s: %s pos must be between %.1f and %.1f\n', ...
                    class(obj), 'move_to', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
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
            % checks go here!
            if back_pos > obj.max_limits(1) || back_pos < obj.max_limits(2)
                fprintf('%s: %s ''back_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'listen_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            if forward_pos > obj.max_limits(1) || forward_pos < obj.max_limits(2)
                fprintf('%s: %s ''forward_pos'' must be between %.1f and %.1f\n', ...
                    class(obj), 'listen_until', obj.max_limits(2), obj.max_limits(1));
                return
            end
            
            if forward_pos > back_pos
                fprintf('%s: %s ''forward_pos'' must be > ''back_pos''\n', ...
                    class(obj), 'listen_until');
                return
            end
            
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
        
        
        function proc = block_test(obj)
            
            fname = obj.full_command('block_test');
            cmd = sprintf('%s', fname);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
            obj.proc_array.add_process(proc);
        end
        
        
        function fname = full_command(obj, cmd)
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end