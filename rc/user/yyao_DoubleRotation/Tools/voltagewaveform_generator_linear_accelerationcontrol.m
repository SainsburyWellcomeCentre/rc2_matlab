function waveform = voltagewaveform_generator_linear_accelerationcontrol(stageparameters, samplingrate)

    rate_speed_to_voltage = 0.05/1.75;

    motion_time = stageparameters.motion_time;
    central_enable = stageparameters.central.enable;
    central_distance = stageparameters.central.distance;
    central_vmax = stageparameters.central.max_vel; 
    central_vmean = stageparameters.central.mean_vel;
    central_peakwidth = stageparameters.central.peakwidth;
    outer_enable = stageparameters.outer.enable;
    outer_distance = stageparameters.outer.distance;
    outer_vmax = stageparameters.outer.max_vel; 
    outer_vmean = stageparameters.outer.mean_vel;
    outer_peakwidth = stageparameters.outer.peakwidth;
    controlled_max = stageparameters.controlled_max;

    waveformlength = motion_time*samplingrate;
    speed = zeros(waveformlength,2);

    if central_enable
        speed_array = speed_generator_linear_accelerationcontrol (central_vmax, central_vmean, central_peakwidth, motion_time, controlled_max);
        if central_distance<0
            speed_array = speed_array*-1;
        end
        N = waveformlength/1000;
        speed(:,1) = interp1(1:N:N*length(speed_array) , speed_array , 1:1:N*length(speed_array) , 'spline');
    end
    if outer_enable
        speed_array = speed_generator_linear_accelerationcontrol (outer_vmax, outer_vmean, outer_peakwidth, motion_time, controlled_max);
        if outer_distance<0
            speed_array = speed_array*-1;
        end
        N = waveformlength/1000;
        speed(:,2) = interp1(1:N:N*length(speed_array) , speed_array , 1:1:N*length(speed_array) , 'spline');
    end

    waveform = speed * rate_speed_to_voltage;
end


function speed = speed_generator_linear_accelerationcontrol (expected_max, expected_mean, peakwidth, duration, controlled_max)
    % generate an unimodal linear speed array with expected mean/max, peakwidth and duration
    vmax = expected_max;
    vmean = expected_mean;
    tx = peakwidth;
    t = duration;

    v = (2*vmean*t - controlled_max*tx) / t;
    a1 = 2*v/(t-tx);
    a2 = 2*(vmax-v)/tx;
    t1 = floor(1000*(t-tx)/t/2);
    t2 = 1000/2 - t1;

    X1 = v/t1:v/t1:v;
    X2 = v+(vmax-v)/t2:(vmax-v)/t2:vmax;
    X3 = vmax:-(vmax-v)/t2:v+(vmax-v)/t2;
    X4 = v:-v/t1:v/t1;
    speed = [X1 X2 X3 X4];
end