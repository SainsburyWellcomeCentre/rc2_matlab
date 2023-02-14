function waveform = voltagewaveform_generator(stageparameters, samplingrate)
    motion_time = stageparameters.motion_time;
    central_enable = stageparameters.central.enable;
    central_distance = stageparameters.central.distance;
    central_vmax = stageparameters.central.max_vel; 
    central_vmean = stageparameters.central.mean_vel;
    outer_enable = stageparameters.outer.enable;
    outer_distance = stageparameters.outer.distance;
    outer_vmax = stageparameters.outer.max_vel; 
    outer_vmean = stageparameters.outer.mean_vel;
    
    length = motion_time*samplingrate;
    position = zeros(length,2);
    speed = ones(length,2);

    rng('shuffle')
    if central_enable
        speed(:,2) = (central_vmax-1)*(rand(1,length)-0.5) + central_vmean;
        for i = 2:length-1
            position(i,2) = position(i-1,2) + speed(i,2)/samplingrate;
        end
        position(end,2) = abs(central_distance);
    end
    if outer_enable
        speed(:,1) = (outer_vmax-1)*(rand(1,length)-0.5) + outer_vmean;
        for i = 2:length-1
            position(i,1) = position(i-1,1) + speed(i,1)/samplingrate;
        end
        position(end,1) = abs(outer_distance);
    end

%     waveform = 800*mapminmax(speed,0,1);
    waveform(:,1) = ones(length);
end