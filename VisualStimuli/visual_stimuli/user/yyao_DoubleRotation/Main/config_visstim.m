function config = config_visstim()

    %%% saving %%%
    config.saving.save_dir = 'C:\Users\Margrie_lab1\Documents\raw_data';

    %%% screen %%%
    config.screen.screen1_resolution      = [2560,1440];
    config.screen.screen234_resolution    = [1280,720];         % each of the combined screen
    config.screen.screen_number           = 1;                  % index of visual stimuli screen
    config.screen.screen_size_px          = [1280*3, 720];
    config.screen.screen_size_mm          = [345*3, 195];
    config.screen.distance_from_screen    = 185;
    
    %%% photodiode %%%
    config.photodiode.photodiode_zone = 200;
    config.photodiode.index = [1];
    config.photodiode.position(1).position   = [0, 0, config.photodiode.photodiode_zone, config.photodiode.photodiode_zone];
    config.photodiode.position(2).position   = [config.screen.screen234_resolution(1), 0, config.screen.screen234_resolution(1)+config.photodiode.photodiode_zone, config.photodiode.photodiode_zone];
    config.photodiode.position(3).position   = [3*config.screen.screen234_resolution(1)-config.photodiode.photodiode_zone 0, 3*config.screen.screen234_resolution(1), config.photodiode.photodiode_zone];

    %%% camera %%%
    config.camera.camera_py = 'C:\Users\Margrie_lab1\Documents\Code\camera\rc_camera.py';

    %%% miniDAQ %%%
    config.nidaq.dev = 'Dev2';                  % device name
    config.nidaq.di.channel_id = 'port0/line0'; % channel to receive DI to trigger visual stimuli
    
%     %%% git %%%
%     config.git.git_dir = 'C:\Users\Margrie_lab1\Documents\Code\visual_stimuli\.git';


    
end