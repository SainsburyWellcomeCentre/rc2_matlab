classdef Soloist < handle
    
    properties
        dir
        limits
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
            obj.limits = [20, 1475];
            
        end
        
        
        function home(obj)
            cmd = obj.full_command('home');
            disp(cmd)
            disp('\n')
            %system(cmd);
        end
        
        
        function disable(obj)
            cmd = obj.full_command('disable');
            disp(cmd)
            disp('\n')
            %system(cmd);
        end

        
        function enable(obj)
            cmd = obj.full_command('enable');
            disp(cmd)
            disp('\n')
            %system(cmd);
        end
        
        
        function move_to(obj, pos, end_enabled)
            % checks go here!
            if pos < obj.limits(1) || pos > obj.limits(2)
                error('position unreasonable')
            end
            
            VariableDefault('end_enabled', false);
            fname = obj.full_command('move_to');
            cmd = sprintf('%s %i %i', fname, pos, end_enabled);
            disp(cmd)
            disp('\n')
            %system(cmd);
        end
        
        
        
        function listen_until(obj, back_pos, forward_pos)
            % checks go here!
            if back_pos < obj.limits(1) || back_pos > obj.limits(2)
                error('position unreasonable')
            end
            
            if forward_pos < obj.limits(1) || forward_pos > obj.limits(2)
                error('position unreasonable')
            end
            
            if forward_pos > back_pos
                error('strange positions')
            end
            
            fname = obj.full_command('listen_until');
            cmd = sprintf('%s %i %i', fname, back_pos, forward_pos);
            disp(cmd)
            disp('\n')
            %system(cmd);
        end
        
        
        
        function fname = full_command(obj, cmd)
            fname = fullfile(obj.dir, sprintf('%s.exe', cmd));
        end
    end
end