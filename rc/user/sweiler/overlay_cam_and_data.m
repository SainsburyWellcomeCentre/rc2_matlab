animal_id = 'CAA-1114768';
session_n = 1;

cam_data_dir = 'C:\Users\Margrie_Lab1\Desktop\cam_test';
bin_data_dir = 'C:\Users\Margrie_Lab1\Documents\temp_data';


show_frames = true;


%% Load data
bin_fname  = fullfile(bin_data_dir, animal_id, sprintf('%s_%i_001.bin', animal_id, session_n));
cam0_fname = fullfile(cam_data_dir, sprintf('%s_%i', animal_id, session_n), 'camera0.mp4');
cam1_fname = fullfile(cam_data_dir, sprintf('%s_%i', animal_id, session_n), 'camera1.mp4');

% create video reader object
vr0 = VideoReader(cam0_fname);
vr1 = VideoReader(cam1_fname);

% load bin data
[data, dt, channel_names, config] = read_rc2_bin(bin_fname);

% preallocate arrays
brightness0 = nan(1, 1e6);
brightness1 = nan(1, 1e6);

% boxes to look at brightness in video frames
y0 = 1:50;
x0 = 1:50;
y1 = 44:84;
x1 = 475:569;


cnt = 0;


while vr1.hasFrame
    
    cnt = cnt + 1;
    
    frame0 = vr0.readFrame();
    frame0 = frame0(:, :, 1);
    brightness0(cnt) = sum(sum(frame0(y0, x0)));
    
    frame1 = vr1.readFrame();
    frame1 = frame1(:, :, 1);
    brightness1(cnt) = sum(sum(frame1(y1, x1)));
    
    if show_frames
        
        if cnt == 1
            figure()
            subplot(1, 2, 1);
            h_im0 = imagesc(frame0);
            axis image
            subplot(1, 2, 2);
            h_im1 = imagesc(frame1);
            axis image
        else
            set(h_im0, 'cdata', frame0);
            set(h_im1, 'cdata', frame1);
        end
        
        pause(1/100)
        title(sprintf('%i', cnt))
    else
        fprintf('%i\n', cnt);
    end
end

% remove any extra entries
brightness0(cnt+1:end) = [];
brightness1(cnt+1:end) = [];



%% Display data
t = (0:size(data, 1)-1)*dt;
figure
hold on
plot(t, data(:, 1)-1.08);

t_cam = t(1:167:end);
% t_cam = (t_cam(1:length(brightness0)) + t_cam(2:length(brightness0)+1))/2;
plot(t_cam, (brightness0(1:length(t_cam))-127500)/1e5)
plot(t_cam, (brightness1(1:length(t_cam))-127500)/1e5)

xlabel('(s)');
ylabel('a.u.');

legend({'Photodiode', 'Cam0 brightness', 'Cam1 brightness'});

