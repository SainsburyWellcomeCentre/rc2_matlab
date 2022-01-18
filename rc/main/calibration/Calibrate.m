classdef Calibrate < handle
% Calibrate Class for aiding with calibration of offsets on the setup
%
%  Calibrate Properties:
%       data            - internal storage of recorded data
%       ctl             - object of class RC2Controller
%       measure_time    - time in seconds to measure voltages
%
%  Calibrate Methods:
%       h_callback      - callback during acquisition
%       measure         - measure voltages on NIDAQ analog input

    properties
        
        data
        ctl
        measure_time = 10
    end
    
    methods
        
        function obj = Calibrate(ctl)
        % Calibrate
        %
        %   Cablibrates(CTL) creates object. CTL is object of class
        %   RC2Controller.
        
            obj.ctl = ctl;
        end
        
        
        
        function h_callback(obj, ~, evt)
        %%h_callback Callback function upon analog input data acquisition
        
            obj.data = cat(1, obj.data, evt.Data);
        end
        
        
        
        function data = measure(obj)
        %%measure Measure voltages on NIDAQ analog input
        %
        %   DATA = measure() measures voltages on the NIDAQ analog input
        %   channels for `measure_time` seconds and returns the data in
        %   DATA.
        
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