animal_id = 'a03';
session_n = 's11';
protocol_name = 'Agatha_02';

cam_data_dir = 'C:\Users\Margrie_Lab1\Desktop\cam_test';
bin_data_dir = 'C:\Users\Margrie_Lab1\Documents\raw_data';

n_cameras = 3;
show_frames = false;



%% Load data
bin_fname  = fullfile(bin_data_dir, animal_id, sprintf('%s_%s_%s.bin', animal_id, session_n,protocol_name));

cam_fname = cell(1, n_cameras);
vr = cell(1, n_cameras);
for cam_i = 1 : n_cameras
    
    cam_fname{cam_i} = fullfile(cam_data_dir, sprintf('%s_%i', animal_id, session_n), sprintf('camera%i.mp4', cam_i-1));
    
    if ~exist(cam_fname{cam_i}, 'file')
        avi_fname = strrep(cam_fname{cam_i}, '.mp4', '.avi');
        cmd = sprintf('ffmpeg -i %s %s', avi_fname, cam_fname{cam_i});
        system(cmd)
    end
    
    vr{cam_i} = VideoReader(cam_fname{cam_i});
end

% load bin data
[data, dt, channel_names, config] = read_rc2_bin(bin_fname);

% preallocate arrays
brightness = nan(cam_i, 1e6);

% boxes to look at brightness in video frames
bbox_x = {1:40, 475:569, 1:400};
bbox_y = {1:50, 44:84, 1:400};

cnt = 0;

while vr{cam_i}.hasFrame
    
    cnt = cnt + 1;
    
    frame = cell(1, n_cameras);
    for cam_i = 1 : n_cameras
        frame{cam_i} = vr{cam_i}.readFrame();
        frame{cam_i} = frame{cam_i}(:, :, 1);
        brightness(cam_i, cnt) = sum(sum(frame{cam_i}(bbox_y{cam_i}, bbox_x{cam_i})));
    end
    
    
    if show_frames
        
        if cnt == 1
            figure()
            for cam_i = 1 : n_cameras
                subplot(1, n_cameras, cam_i);
                h_im(cam_i) = imagesc(frame{cam_i});
                axis image
            end
        else
            for cam_i = 1 : n_cameras
                set(h_im(cam_i), 'cdata', frame{cam_i});
            end
        end
        
        pause(1/100)
        title(sprintf('%i', cnt))
    else
        fprintf('%i\n', cnt);
    end
end

% remove any extra entries
brightness(:, cnt+1:end) = [];


%% Display data
n_samples_per_trigger = 167;
pd_offset = 1.08;
cam_offset = 127500;

t = (0:size(data, 1)-1)*dt;

figure
hold on
plot(t, data(:, 1) - pd_offset);

t_cam = t(1:n_samples_per_trigger:end);


% t_cam = (t_cam(1:length(brightness0)) + t_cam(2:length(brightness0)+1))/2;
for cam_i = 1 : n_cameras
    if length(t_cam) > size(brightness, 2)
        plot(t_cam(1:size(brightness, 2)), (brightness(cam_i, :) - cam_offset)/1e5);
    else
        plot(t_cam, (brightness(cam_i, 1:length(t_cam)) - cam_offset)/1e5)
    end
end

xlabel('(s)');
ylabel('a.u.');

legend({'Photodiode', 'Cam0 brightness', 'Cam1 brightness', 'Cam2 brightness'});

