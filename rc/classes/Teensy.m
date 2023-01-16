classdef Teensy < handle
    % Teensy class for handling loading of scripts to the Teensy.

    properties
        enabled % Boolean specifying whether the module is used.
        exe % Full path of the Arduino executable file.
        dir % Directory containing relevant .ino files.
    end
    
    properties (SetAccess = private)
        current_script % Name of currently loaded script.
    end
        
    
    
    methods
        function obj = Teensy(config, force)
            % Constructor for a :class:`rc.classes.Teensy` device.
            %
            % :param config: The main configuration structure.
            % :param force: Optional boolean specifying whether to forcefully load the script in config.teensy.start_script.
        
            VariableDefault('force', true);
            
            obj.enabled = config.teensy.enable;
            if ~obj.enabled, return, end
            
            obj.exe = config.teensy.exe;
            obj.dir = config.teensy.dir;
            obj.current_script = config.teensy.start_script;
            obj.load(obj.current_script, force);
        end
        
        
        
        function load(obj, script, force)
            % Loads a script onto the Teensy.
            %
            % :param script: Name of the script to load. If name matches string in :attr:`current_script` nothing happens unless ``force`` is true. Name should be supplied without the .ino extension.
            % :param force: Optional boolean specifying whether to forcefully load the named ``script``.
        
            VariableDefault('force', false);
            
            if ~obj.enabled, return, end
            
            if strcmp(obj.current_script, script) && ~force
                disp('no need to load Teensy')
                return
            end
            
            cmd = sprintf('"%s" --upload %s', obj.exe, obj.full_script(script));
            system(cmd)
            
            obj.current_script = script;
        end
        
        
        
        function fname = full_script(obj, script)
            % Get full path of the .ino script given a script name.
            %
            % :param script: Name of the script.
            % :return: The full path to the script.
        
            fname = fullfile(obj.dir, script, sprintf('%s.ino', script));
        end
    end
end
