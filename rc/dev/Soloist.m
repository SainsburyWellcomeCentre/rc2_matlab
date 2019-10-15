classdef Soloist < handle
    
    properties
        dir
        max_limits
    end
    
    methods
        
        function obj = Soloist(config, home_prompt)
            
            obj.dir = config.soloist.dir;
            if home_prompt
                user_ans = input('Home soloist? (y/n)', 's');
                if any(strcmp(user_ans, {'yes', 'y', 'Y'}))
                    obj.home();
                end
            end
            obj.max_limits = config.stage.max_limits;
        end
        
        
        function home(obj)
            cmd = obj.full_command('home_');
            disp(cmd)
%             % start running the process
%             runtime = java.lang.Runtime.getRuntime();
%             proc = runtime.exec(cmd);
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
            cmd = obj.full_command('reset_');
            disp(cmd)
        end
        
        
        function move_to(obj, pos, end_enabled)
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
            
            VariableDefault('end_enabled', false);
            
            if ~islogical(end_enabled)
                fprintf('%s: %s ''end_enabled'' must be boolean\n', class(obj), 'move_to');
                return
            end
            
            % convert to logical
            end_enabled = logical(end_enabled);
            
            fname = obj.full_command('move_to_');
            cmd = sprintf('%s %i %i', fname, pos, end_enabled);
            disp(cmd)
            
%             % start running the process
%             runtime = java.lang.Runtime.getRuntime();
%             proc = runtime.exec(cmd);
        end
        
        
        
        function listen_until(obj, back_pos, forward_pos)
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
            
            fname = obj.full_command('listen_until_');
            cmd = sprintf('%s %i %i', fname, back_pos, forward_pos);
            disp(cmd)
            
%             % start running the process
%             runtime = java.lang.Runtime.getRuntime();
%             proc = runtime.exec(cmd);
        end
        
        
        function proc = block_test(obj)
            
            fname = obj.full_command('block_test');
            cmd = sprintf('%s', fname);
            disp(cmd)
            
            % start running the process
            runtime = java.lang.Runtime.getRuntime();
            p_java = runtime.exec(cmd);
            proc = ProcHandler(p_java);
        end
        
        
        function fname = full_command(obj, cmd)
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end