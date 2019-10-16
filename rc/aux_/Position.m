classdef Position < handle
    
    properties
        dt
        position
        integrate_on
    end
    
    
    methods
        function obj = Position(config)
            obj.dt = 1/config.nidaq.rate;
        end
        
        
        function integrate(obj, data)
            if ~obj.integrate_on; return; end
            
            % convert to cm/s
            obj.position = obj.position + sum(data)*obj.dt;
        end
        
        
        function reset(obj)
            obj.position = 0;
        end
        
        
        function start(obj)
            obj.reset()
            obj.integrate_on = true;
        end
        
        
        function stop(obj)
            obj.integrate_on = false;
        end
        
        
        function integrate_until(obj, back, forward)
            obj.start()
            while obj.position < forward && obj.position > back
                pause(0.01);
            end
            obj.stop()
        end
    end
end