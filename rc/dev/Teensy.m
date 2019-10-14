classdef Teensy < handle
    
    properties
        exe
        dir
        current_script
    end
    
    
    methods
        function obj = Teensy(config)
            obj.exe = config.teensy.exe;
            obj.dir = config.teensy.dir;
            obj.current_script = config.teensy.start_script;
            obj.load(obj.current_script, true);
        end
        
        
        function load(obj, script, force)
            % script = 'forward_only' or 'forward_and_backward'
            VariableDefault('force', false);
            
            if strcmp(obj.current_script, script) && ~force
                fprintf('no need to load Teensy')
                return
            end
            
            cmd = sprintf('%s --upload %s', obj.exe, obj.full_script(script));
            disp(cmd)
            disp('\n')
            %system(cmd)
            
            obj.current_script = script;
        end
        
        
        function fname = full_script(obj, script)
            fname = fullfile(obj.dir, script, sprintf('%s.ino', script));
        end
    end
end