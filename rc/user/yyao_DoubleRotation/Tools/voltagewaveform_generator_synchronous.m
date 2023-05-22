function waveform = voltagewaveform_generator_synchronous(stageparameters, samplingrate)

    rate_speed_to_voltage = 0.05;

    motion_time = stageparameters.motion_time;
    central_enable = stageparameters.central.enable;
    central_distance = stageparameters.central.distance;
    central_vmax = stageparameters.central.max_vel; 
    central_vmean = stageparameters.central.mean_vel;
    outer_enable = stageparameters.outer.enable;
    outer_distance = stageparameters.outer.distance;
    outer_vmax = stageparameters.outer.max_vel; 
    outer_vmean = stageparameters.outer.mean_vel;

    waveformlength = motion_time*samplingrate;
    speed = zeros(waveformlength,2);

    if central_enable
        speed_array = speed_generator (central_vmax, central_vmean);
        if central_distance<0
            speed_array = speed_array*-1;
        end
        N = waveformlength/1000;
        speed(:,1) = interp1(1:N:N*length(speed_array) , speed_array , 1:1:N*length(speed_array) , 'spline');
    end
    if outer_enable
        speed(:,2) = speed(:,1);
    end

    waveform = speed * rate_speed_to_voltage;
end



function r= random_number (r_min, r_max, N)
    % generate N random numbers in range [r_min, r_max]
    rng('shuffle');
    r = (r_max-r_min).*rand(N,1) + r_min;
end

function speed = speed_generator (expected_max, expected_mean)
    % generate an 1*1000 unimodal speed array with expected max & mean and random peak location
    rng('shuffle');
    gain = 1000;
    X1 = random('Poisson', expected_mean* gain, 1, 200)/gain;
    X2 = normrnd(expected_mean, 1, 1, 300);
    X3 = normrnd(expected_mean, 8.5, 1, 200);
    X = [X1 X2 X3];
    for i = 1:length(X)
        if X(i)<0
            X(i) = -X(i);
        end
    end
    while sum(X>expected_max)>0
        for i = 1:length(X)
            if X(i) > expected_max
                X(i) = X(i) - random_number(0, expected_mean,1);
            end
        end
    end
    X(end+1) = expected_max;
    n = length(X);
    for i = n+1 : 1000
        if mean(X) > expected_mean
            X(i) = random_number(min(X), expected_mean, 1);
        else
            X(i) = random_number(expected_mean, max(X), 1);
        end
    end
    Xsort = sort(X, 'ascend');

    m = [1, 1, 2, 1, 3, 2, 3, 4, 2, 3, 4, 5, 3, 5, 4, 5, 3,  7;  ...
         2, 3, 3, 4, 4, 5, 5, 5, 7, 7, 7, 7, 8, 8, 9, 9, 10, 10];
    p = randperm(length(m),1);

    index=[];
    for i=1:m(1,p)
        index = union(index , i:m(2,p):1000);
    end
    speed(1:length(index),1) = sort(Xsort(index),'ascend');
    speed((length(index)+1):1000,1) = sort(Xsort(setdiff(1:1000 , index)), 'descend');

end