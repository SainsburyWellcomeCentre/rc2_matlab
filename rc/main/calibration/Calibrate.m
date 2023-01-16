classdef Calibrate < handle
    % Calibration class for aiding with calibration of offsets on the setup.

    properties
        data % Internal storage of recorded data.
        ctl % :class:`rc.main.Controller` object.
        measure_time = 10 % Time in seconds to measure voltages
    end
    
    methods
        function obj = Calibrate(ctl)
            % Constructor for a :class:`rc.main.Calibrate` class.
            %
            % :param ctl: A :class:`rc.main.Controller` object.
        
            obj.ctl = ctl;
        end
        
        
        function h_callback(obj, ~, evt)
            % Callback function upon analog input data acquisition.
        
            obj.data = cat(1, obj.data, evt.Data);
        end
        
        
        function data = measure(obj)
            % Measure voltages on NIDAQ analog input.
            %
            % :return data: Voltage measured on analog input channels for :attr:`measure_time`.
        
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