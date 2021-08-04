classdef Teensy < handle
    
    properties
        
        enabled
        exe
        dir
        current_script
    end
    
    
    methods
        
        function obj = Teensy(config, force)
            
            VariableDefault('force', true);
            
            obj.enabled = config.teensy.enable;
            if ~obj.enabled, return, end
            
            obj.exe = config.teensy.exe;
            obj.dir = config.teensy.dir;
            obj.current_script = config.teensy.start_script;
            obj.load(obj.current_script, force);
        end
        
        
        function load(obj, script, force)
            % script = 'forward_only' or 'forward_and_backward'
            %   'calibration_soloist'
            
            if ~obj.enabled; return; end
            
            VariableDefault('force', false);
            
            if ~obj.enabled, return, end
            
            if strcmp(obj.current_script, script) && ~force
                disp('no need to load Teensy')
                return
            end
            
            cmd = sprintf('"%s" --upload %s', obj.exe, obj.full_script(script));
%             disp(cmd)
            system(cmd)
            
            obj.current_script = script;
        end
        
        
        function fname = full_script(obj, script)
            fname = fullfile(obj.dir, script, sprintf('%s.ino', script));
        end
    end
end
