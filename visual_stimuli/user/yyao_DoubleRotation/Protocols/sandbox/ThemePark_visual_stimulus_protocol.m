function ThemePark_visual_stimulus_protocol(tp_main, save_fname)
%{
screen_number           = 1;                % number of combined screen
screen_size_px          = [960, 540];
screen_size_mm          = [345, 195];
apply_gamma_correction  = true;
gamma_correction_file   = 'gamma_correction_new8dream.mat';
git_version             = tp_main.current_git_version();

grating_1_position      = [0, 0, 960, 540];
grating_2_position      = [960, 0, 2*960, 540];
photodiode_1_position   = [760, 0, 960, 200];
photodiode_2_position   = [960, 0, 1160, 200];
%}

% ----------------------------------------
% modified by Yanting Yao on 25/2/2022
% %{
screen1_resolution = [2560,1440];
screen23_resolution = [1280,720];  % 
screen_number           = 1;                % number of combined screen
screen_size_px          = [960, 540]*screen23_resolution(1)/960;
screen_size_mm          = [345, 195];
apply_gamma_correction  = true;
gamma_correction_file   = 'gamma_correction_new8dream.mat';
git_version             = tp_main.current_git_version();

grating_1_position      = [0, 0, 960, 540]*screen23_resolution(1)/960;
grating_2_position      = [960, 0, 2*960, 540]*screen23_resolution(1)/960;
photodiode_1_position   = [760, 0, 1160, 200]*screen23_resolution(1)/960;

%}
% modified by Yanting Yao on 25/2/2022
% ----------------------------------------

distance_from_screen    = 100;

protocol_name = tp_main.protocol_name;
vis_protocol = feval(protocol_name);
cycles_per_degree       = vis_protocol.cycles_per_degree;
cycles_per_s_all        = vis_protocol.cycles_per_s_all;
n_s_plus_trials         = vis_protocol.n_s_plus_trials;
n_s_minus_trials        = vis_protocol.n_s_minus_trials;
n_trials                = vis_protocol.n_trials;
s_plus = [];
cycles_per_s = [];


%testing different paremeters, edited by Agatha on 23/08/2021
baseline_s              = 5;
prestim_wait_s          = 3;
drift_duration_s        = 4;
poststim_wait_s         = 1;


% baseline_s              = 5;
% prestim_wait_s          = 11;
% drift_duration_s        = 4;
% poststim_wait_s         = 1;


white_val               = 1;
black_val               = 0;

nidaq_dev               = 'Dev2';
ao_chan                 = 'ao0';
ao_start                = 5;



grey_val                = (white_val+black_val)/2;
col_range               = abs(white_val - black_val)/2;

radians_per_cycle       = (pi/180) * (1/cycles_per_degree);
mm_per_cycle            = 2*distance_from_screen * tan(radians_per_cycle/2);
cycles_per_mm           = 1 / mm_per_cycle;
mm_per_pixel            = screen_size_mm(1) / screen_size_px(1);
cycles_per_pixel        = cycles_per_mm * mm_per_pixel;
pixels_per_cycle        = ceil(1/cycles_per_pixel);

% mm_per_degree           = distance_from_screen * tan(pi/180);
% mm_per_pixel            = screen_size_mm(1) / screen_size_px(1);
% degrees_per_pixel       = mm_per_pixel / mm_per_degree;
% cycles_per_pixel        = cycles_per_degree * degrees_per_pixel;
% pixels_per_cycle        = ceil(1/cycles_per_pixel);

pixel_coordinates       = (-screen_size_px(1)/2 : (screen_size_px(1)/2 + pixels_per_cycle));
spatial_frequency       = 2 * pi * cycles_per_pixel;

% 1D grating
grating                 = grey_val + col_range * cos(spatial_frequency * pixel_coordinates);
grating                 = round(grating);

% add analog ouput to approximate photodiode
ao = daq('ni');
ao.addoutput(nidaq_dev, ao_chan, 'Voltage');
write(ao, 0);


try
    
    Screen('Preference', 'SkipSyncTests', 2);
    PsychDefaultSetup(2); 
    
    if apply_gamma_correction
        load(gamma_correction_file, 'gamma_table');
        original_gamma_table_1 = Screen('LoadNormalizedGammaTable', 1, gamma_table, 0);
        original_gamma_table_2 = Screen('LoadNormalizedGammaTable', 2, gamma_table, 0);
         %original_gamma_table_2 = Screen('LoadNormalizedGammaTable', 3, gamma_table, 0);
    end
    
%     window = PsychImaging('OpenWindow', screen_number, grey_val);
    window = PsychImaging('OpenWindow', screen_number, grey_val, [screen1_resolution(1),0,2*screen23_resolution(1)+screen1_resolution(1),screen23_resolution(2)]);  % modified by Yanting Yao on 25/2/2022
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    s_per_frame = Screen('GetFlipInterval', window);
%     Priority(MaxPriority(window));
    grating_texture = Screen('MakeTexture', window, grating);
    
    % get initial timestamp
    vbl = Screen('Flip', window);
    
    % number of frames for each part of stimulus
    n_drift_frames = ceil(drift_duration_s / s_per_frame);
    n_baseline_frames = ceil(baseline_s / s_per_frame);
    n_prestim_frames = ceil(prestim_wait_s / s_per_frame);
    n_poststim_frames = ceil(poststim_wait_s / s_per_frame);
    
    
    fprintf('prepare to start\n');
    tp_main.tcp_server.writeline('ready');

    %% run visual stimulation 
%     tp_main.setup_complete();
    
    
    % present baseline
    for frame_i = 1 : n_baseline_frames
        
        Screen('FillRect', window, grey_val);
        vbl = Screen('Flip', window, vbl + 0.5*s_per_frame);
        if KbCheck; error('escape_1'); end
    end
    
    % loop through stimuli
    for stim_i = 1 : n_trials   % start trial

        % get current trial vis_stim information
        type_id = tp_main.tcp_server_stimulus.readline();
        vis_protocol.vis_stim_type(type_id);
        s_plus(stim_i)                  = vis_protocol.s_plus;
        cycles_per_s(stim_i,:)            = vis_protocol.cycles_per_s;
        
        fprintf('notifying RC2 of stimulus type received\n');
        tp_main.tcp_server_stimulus.writeline('received');
        if s_plus(stim_i)
            fprintf('Trial %i, stimulus: s_plus\n', stim_i);
        else
            fprintf('Trial %i, stimulus: s_minus\n', stim_i);
        end

        
        % wait for trial start
        fprintf('waiting for starting signal from RC2\n');
        reply_status = tp_main.wait_for_rc2();
        fprintf('trial start command received\n');
        
        
        % if other computer has stopped break and cleanup
        if reply_status == -1
            sca;
            fprintf('stopping visual stimulus on: %i\n', stim_i);
            break
            % TODO: abort and reset?
        end

        pixel_shift_per_frame_1 = -pixels_per_cycle * cycles_per_s(stim_i,1) * s_per_frame;
        pixel_shift_per_frame_2 = pixels_per_cycle * cycles_per_s(stim_i,2) * s_per_frame;
        
        for frame_i = 1 : n_prestim_frames
            
            Screen('FillRect', window, grey_val);
            vbl = Screen('Flip', window, vbl + 0.5*s_per_frame);
            
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape_during_isi'), end
%             if KbCheck; error('escape_during_isi'); end
        end
        
        
        tocs = nan(n_drift_frames, 1);
        tic();
        for frame_i = 1 : n_drift_frames
            
            xoffset_1 = mod((frame_i-1) * pixel_shift_per_frame_1, pixels_per_cycle);
            xoffset_2 = mod((frame_i-1) * pixel_shift_per_frame_2, pixels_per_cycle);
            
            source_rectangle_1 = [xoffset_1, 0, xoffset_1 + screen_size_px(1), screen_size_px(1)];
            source_rectangle_2 = [xoffset_2, 0, xoffset_2 + screen_size_px(1), screen_size_px(1)];
            
            Screen('DrawTexture', window, grating_texture, source_rectangle_1, grating_1_position);
            Screen('DrawTexture', window, grating_texture, source_rectangle_2, grating_2_position);
            Screen('FillRect', window, white_val, photodiode_1_position);
%             Screen('FillRect', window, white_val, photodiode_2_position);
            
            vbl = Screen('Flip', window, vbl + 0.5*s_per_frame);
            tocs(frame_i) = toc();
            
            if frame_i == 1
                write(ao, ao_start);
            elseif frame_i == n_drift_frames
                write(ao, 0);
            end
            
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape_during_drift'), end
%             if KbCheck; error('escape_during_drift'); end
        end
        
        fprintf('average loop time: %.10f (n=%i)\n', mean(diff(tocs)), n_drift_frames);
        
        for frame_i = 1 : n_poststim_frames
            
            Screen('FillRect', window, grey_val);
            vbl = Screen('Flip', window, vbl + 0.5*s_per_frame);
            
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape_during_isi'), end
%             if KbCheck; error('escape_during_isi'); end
        end

        fprintf('waiting for motion end signal from RC2\n');
        reply_status = tp_main.wait_for_rc2();
        fprintf('motion end status received\n');

        % send message that the trial has ended
        tp_main.tcp_server_stimulus.writeline('trial_end');
    end
    
    vars_to_save = {'git_version'
        's_plus'
        'protocol_name'
        'save_fname'
        'screen_number'
        'screen_size_px'
        'screen_size_mm'
        'apply_gamma_correction'
        'gamma_correction_file'
        'grating_1_position'
        'grating_2_position'
        'distance_from_screen'
        'cycles_per_degree'     
        'cycles_per_s_all'      
        'baseline_s'            
        'prestim_wait_s'        
        'drift_duration_s'      
        'poststim_wait_s'       
        'white_val'             
        'black_val'             
        'nidaq_dev'             
        'ao_chan'               
        'ao_start'              
        'n_s_plus_trials'       
        'n_s_minus_trials'      
        'n_trials'              
        'cycles_per_s'
        'grey_val'              
        'col_range'             
        'radians_per_cycle'     
        'mm_per_cycle'          
        'cycles_per_mm'         
        'mm_per_pixel'          
        'cycles_per_pixel'      
        'pixels_per_cycle'      
        'pixel_coordinates'     
        'spatial_frequency'     
        'grating'               
        'original_gamma_table_1'
        'gamma_table'           
        'original_gamma_table_2'
        's_per_frame'           
        'n_drift_frames'        
        'n_baseline_frames'     
        'n_prestim_frames'      
        'n_poststim_frames'};
    
    save(save_fname, vars_to_save{:});
    
    if exist('original_gamma_table_1', 'var')
        Screen('LoadNormalizedGammaTable', 1, original_gamma_table_1, 0);
        Screen('LoadNormalizedGammaTable', 2, original_gamma_table_2, 0);
        %Screen('LoadNormalizedGammaTable', 3, original_gamma_table_2, 0);
    end
    sca;
    fprintf('Protocol finished\n');
    
catch ME
    
    if exist('original_gamma_table_1', 'var')
        Screen('LoadNormalizedGammaTable', 1, original_gamma_table_1, 0);
        Screen('LoadNormalizedGammaTable', 2, original_gamma_table_2, 0);
        %Screen('LoadNormalizedGammaTable', 3, original_gamma_table_2, 0);
    end
    tp_main.is_running = false;
    sca;
    rethrow(ME);
end
