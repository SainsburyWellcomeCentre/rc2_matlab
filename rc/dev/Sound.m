classdef Sound < handle
    
    properties
        
        looping
    end
    
    
    properties (SetAccess = private)
        
        audio
        state = false;
    end
    
    properties (SetAccess = private, SetObservable = true)
        
        enabled
    end
    
    
    
    methods
        
        function obj = Sound()
            % load a predefined audio file
            %    this could become an option, but it is unlikely to change
            try
                [y, rate] = audioread('white_noise.wav', 'native');
                obj.audio = audioplayer(y, rate);
                obj.looping = true;
                set(obj.audio, 'StopFcn', @(x, y)obj.repeat(x, y))
                obj.enabled = true;
            catch ME
                % upon failure disable the sound
                obj.enabled = false;
                obj.looping = false;
                rethrow(ME);
            end
        end
        
        
        function play(obj)
            % if sound is currently disabled or it is already running
            % do nothing.
            if ~obj.enabled; return; end
            if obj.state; return; end
            
            play(obj.audio)
            obj.state = true;
        end
        
        
        function repeat(obj, ~, ~)
            %
            if obj.looping
                % set state to false or it won't play again
                obj.state = false;
                % just start play again
                obj.play()
            end
        end
        
        
        function enable(obj)
            obj.enabled = true;
        end
        
        
        function disable(obj)
            % stop the sound and set enabled flag to false
            obj.stop();
            obj.enabled = false;
        end
        
        
        function stop(obj)
            % if sound is currently disabled or it is not running
            % do nothing.
            if ~obj.enabled; return; end
            if ~obj.state; return; end
            
            % stop sound and set state to false
            stop(obj.audio);
            obj.state = false;
        end
    end
end