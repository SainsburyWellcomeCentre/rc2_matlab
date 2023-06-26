classdef TimedSound < handle
    % Sound class for playing a sound for a specified time interval
    
    properties (SetAccess = private)
        audio % `audioplayer <https://uk.mathworks.com/help/matlab/ref/audioplayer.html>`_ object.
        reset % Helper `audioplayer <https://uk.mathworks.com/help/matlab/ref/audioplayer.html>`_ object.
        state = false; % Current state of the audio.
        sound_timer % Timer for timing sound play.
    end
    
    properties (SetAccess = private, SetObservable = true)
        enabled = true % Whether to use this module (default true).
    end
    
    methods
        function obj = TimedSound(sound_file) 
            % Constructor for a :class:`rc.dev.TimedSound` device.
            
            try
                % load a hard-coded audio file
                [y, rate] = audioread(sound_file, 'native');
                
                % create the main audio play object
                obj.audio = audioplayer(y, rate);
                
                % upon stopping we need to reset the voltage on the jack to
                % zero
                obj.reset = audioplayer([0, 0, 0], rate);
                
                % set the audio to loop until stopped
                set(obj.audio, 'StopFcn', @(o, e)obj.repeat_callback(o, e))
                
                obj.enabled = true;
                
            catch ME
                
                % upon failure disable the sound and don't loop
                obj.enabled = false;
                rethrow(ME);
            end
        end
        
        function enable(obj)
            % Enable the device.
        
            obj.enabled = true;
        end
        
        function disable(obj)
            % Disable the device and stop sound.
        
            % stop the sound and set enabled flag to false
            obj.stop();
            obj.enabled = false;
        end
        
        function play_for(obj, for_s)
           % play sound for some amount of time in s. 
           
           if ~obj.enabled; return; end
           if obj.state; return; end
           
           % set up a timer to stop the sound
%            obj.sound_timer = timer('StartDelay', for_s, 'TimerFcn', @(o, e)obj.stop_callback(o, e));
           obj.sound_timer = timer('StartDelay', for_s, 'TimerFcn', @(o, e)obj.stop_callback(o, e));
           start(obj.sound_timer);
            
           % start playing the sound and set state to true
           play(obj.audio)
           obj.state = true;
        end
        
        function stop(obj)
            % Stop the sound.
        
            % if sound is currently disabled or it is not running.
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
        
        function stop_callback(obj, ~, ~)
            obj.stop();
        end
        
        function repeat_callback(obj, ~, ~)
            % Callback for repeating the sound.
        
            % if state is false, don't start again.
            if ~obj.state; return; end
            
            % just start playing again
            play(obj.audio)
        end
    end
end

