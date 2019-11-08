classdef Position < handle
    
    properties
        dt
        position = 0
        deadband
        integrate_on
    end
    
    
    methods
        function obj = Position(config)
            obj.dt = 1/config.nidaq.rate;
            obj.deadband = config.position.deadband;
        end
        
        
        function integrate(obj, data)
            if ~obj.integrate_on; return; end
            
            % convert to cm
            obj.position = obj.position + sum(data(abs(data) > obj.deadband))*obj.dt;
            fprintf('%.2f\n', obj.position);
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
        
        
        function integrate_until(obj, backward_mm, forward_mm)
            backward_cm = backward_mm/10;
            forward_cm = forward_mm/10;
            obj.start()
            while obj.position < forward_cm && obj.position > backward_cm
                pause(0.005);
            end
            obj.stop()
        end
    end
end