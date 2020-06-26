classdef Calibrate < handle
    
    properties
        data
        ctl
        measure_time = 10
    end
    
    methods
        
        function obj = Calibrate(ctl)
            obj.ctl = ctl;
        end
        
        function h_callback(obj, ~, evt)
            
            obj.data = cat(1, obj.data, evt.Data);
        end
        
        function data = measure(obj)
            
            obj.data = [];
            
            % setup callback to log data to temporary file
            obj.ctl.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            
            % run for measure_time seconds
            obj.ctl.ni.start_acq(false);  % do not start clock
            
            tic;
            while toc < obj.measure_time
                pause(0.05)
            end
            
            % stop acquiring
            obj.ctl.ni.stop_acq(false);
            
            % return the data
            data = obj.data;
        end
    end
end