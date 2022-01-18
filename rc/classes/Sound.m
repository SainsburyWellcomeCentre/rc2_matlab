classdef Sound < handle
% Sound Class for handling sound output
%
%   Sound Properties:
%       enabled         - whether to use this module (default true)
%       looping         - whether to loop the sound (default true)
%       audio           - object of class audioplayer
%       reset           - helper object of class audioplayer
%       state           - current state of the audio       
%
%   Sound Methods:
%       enable          - enable the module
%       disable         - disable the module (stop the sound as well)
%       play            - play the sound
%       stop            - stop the sound
%       repeat          - callback for repeating the sound
%
%   See also: audioplayer

    properties
        
        looping = true
    end
    
    
    properties (SetAccess = private)
        
        global_enabled
        audio
        reset
        state = false;
    end
    
    properties (SetAccess = private, SetObservable = true)
        
        enabled = true
    end
    
    
    
    methods
        
        function obj = Sound(config)
            
            obj.global_enabled = config.sound.enable;
            if ~obj.global_enabled, return, end
            
            obj.enabled = false;
            return
            try
                
                % load a hard-coded audio file
                %   this could become an option, but it is unlikely to change
                %   if it doesn't exist, this will fail and the sound will
                %   be disabled
                [y, rate] = audioread(config.sound.filename, 'native');
                
                % create the main audio play object
                obj.audio = audioplayer(y, rate);
                
                % upon stopping we need to reset the voltage on the jack to
                % zero... apparently without this, a voltage remains on
                % it?
                obj.reset = audioplayer([0, 0, 0], rate);
                
                % When the sound stops, run the repeat function to start
                % it.
                set(obj.audio, 'StopFcn', @(x, y)obj.repeat(x, y))
                
                % by default the sound is on, and it loops
                obj.enabled = true;
                obj.looping = true;
                
            catch ME
                
                % upon failure disable the sound and don't loop
                obj.enabled = false;
                obj.looping = false;
                warning('initializing sound failed.')
%                 rethrow(ME);
            end
        end
        
        
        function enable(obj)
        %%enable Enable the module
        %
        %   enable()
            
            if ~obj.global_enabled, return, end
            obj.enabled = true;
        end
        
        
        function disable(obj)
        %%disable Disable the module (stop the sound as well)
        %
        %   disable()
        
            if ~obj.global_enabled, return, end
            
            % stop the sound and set enabled flag to false
            obj.stop();
            obj.enabled = false;
        end
        
        
        function play(obj)
        %%play Play the sound
        %
        %   play() starts playing the sound.
        
            if ~obj.global_enabled, return, end
            % if sound is currently disabled or it is already running
            % do nothing.
            if ~obj.enabled; return; end
            if obj.state; return; end
            
            % start playing the sound and set state to true
            play(obj.audio)
            obj.state = true;
        end
        
        
        function stop(obj)
        %%stop Stop the sound
        %
        %   stop() stops playing the sound.
        
            if ~obj.global_enabled, return, end
            
            % if sound is currently disabled or it is not running
            % do nothing.
            if ~obj.enabled; return; end
            if ~obj.state; return; end
            
            % set state to false here... otherwise repeat will run on
            % stopping and start again
            obj.state = false;
            % stop sound and set state to false
            stop(obj.audio);
            
            % we need to play a short burst of 0's to reset the output to
            % zero...
            play(obj.reset);
        end
        
        
        function repeat(obj, ~, ~)
        %%repeat Callback for repeating the sound
        %
        %   repeat() repeats the sound.
        
            if ~obj.global_enabled, return, end
            
            % if state is false, don't start again.
            if ~obj.state; return; end
            
            % if set to loop and the state has not been set to false, we
            % start the sound again.
            if obj.looping
                % set state to false or it won't play again
                obj.state = false;
                % just start playing again
                obj.play()
            end
        end
    end
end
