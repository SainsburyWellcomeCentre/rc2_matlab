classdef Sound < handle
    
    properties
        audio
        looping = false;
    end
    
    
    
    methods
        
        function obj = Sound()
            [y, rate] = audioread('white_noise.wav', 'native');
            obj.audio = audioplayer(y, rate);
            set(obj.audio, 'StopFcn', @(x, y)obj.repeat(x, y))
        end
        
        
        function start(obj)
            obj.looping = true;
            play(obj.audio)
        end
        
        
        function repeat(obj, ~, ~)
            if obj.looping
                obj.start()
            end
        end
        
        
        function stop(obj)
            obj.looping = false;
            stop(obj.audio);
        end
    end
end