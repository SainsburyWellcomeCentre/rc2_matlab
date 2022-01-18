classdef Teensy < handle
% Teensy Class for handling loading of scripts to the Teensy
%
%   Teensy Properties:
%       exe             - full path of the Arduino executable file
%       dir             - directory containing all the .ino files
%       current_script  - name of script currently loaded
%
%   Teensy Methods:
%       load            - load the script onto the Teensy
%       full_script     - full path of the .ino script given a script name
%
%   See also the README in the Teensy directory.

    properties
        exe
        dir
        current_script
    end
    
    
    methods
        
        function obj = Teensy(config, force)
        % Teensy
        %
        %   Teensy(CONFIG, FORCE) creates an object of class Teensy. CONFIG
        %   is the configuration structure of the setup. FORCE is optional
        %   and is a boolean (default true) determining whether to
        %   forcefully load onto the teensy the script in
        %   config.teensy.start_script. 
        %
        %   See also: load
        
            VariableDefault('force', true);
            
            obj.exe = config.teensy.exe;
            obj.dir = config.teensy.dir;
            obj.current_script = config.teensy.start_script;
            obj.load(obj.current_script, force);
        end
        
        
        function load(obj, script, force)
        %%load Loads a script onto the Teensy
        %
        %   load(SCRIPT_NAME, FORCE) loads the script with script name
        %   SCRIPT_NAME (a string). If SCRIPT_NAME matches the string in
        %   `current_script` nothing happens, unless FORCE is set to true.
        %   If FORCE is true then the script is loaded whatever.
        %
        %   Scipt names are the name of the .ino, but without the .ino
        %   suffix (e.g. 'forward_only').
        
            VariableDefault('force', false);
            
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
        %%full_script Full path of the .ino script given a script name
        %
        %   FULLNAME = full_script(SCRIPT_NAME) creates the full path to
        %   the script with script name SCRIPT_NAME (a string). 
        
            fname = fullfile(obj.dir, script, sprintf('%s.ino', script));
        end
    end
end
