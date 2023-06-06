classdef vis_stim_Texture < handle

    % to present grating visual stimuli via Psychtoolbox

    properties

        tp_main
        save_fname
        visstim_data
        original_gamma_table_1
        original_gamma_table_2

    end

    properties (SetAccess = private)

        screen1_resolution
        screen234_resolution
        screen_number
        screen_size_px
        screen_size_mm
        distance_from_screen

        imagepath
        
        photodiode_index
        photodiode_position
        
    end




    methods

        function obj = vis_stim_Texture(config)

            obj.screen1_resolution      = config.screen.screen1_resolution;
            obj.screen234_resolution    = config.screen.screen234_resolution;
            obj.screen_number           = config.screen.screen_number;          % index of combined screen
            obj.screen_size_px          = config.screen.screen_size_px;
            obj.screen_size_mm          = config.screen.screen_size_mm;
            obj.distance_from_screen    = config.screen.distance_from_screen;

            obj.imagepath = 'C:\Users\Margrie_Lab1\Documents\tools\zebra texture.bmp';

            obj.photodiode_index = config.photodiode.index;
            obj.photodiode_position = config.photodiode.position;
            
        end



        function run(obj,tp_main,save_fname)

            h = onCleanup(@obj.cleanup);
            
            obj.tp_main = tp_main;
            obj.save_fname = save_fname;
            obj.visstim_data.git_version             = tp_main.current_git_version();
            screen_number           = obj.screen_number;
            screen_size_px          = obj.screen_size_px;
            screen_size_mm          = obj.screen_size_mm;
            distance_from_screen    = obj.distance_from_screen;
            obj.visstim_data.apply_gamma_correction  = true;
            obj.visstim_data.gamma_correction_file   = 'gamma_correction_new8dream.mat';
            %% settings

            obj.visstim_data.n_s_plus_trials         = obj.tp_main.vis_protocol.n_s_plus_trials;
            obj.visstim_data.n_s_minus_trials        = obj.tp_main.vis_protocol.n_s_minus_trials;
            obj.visstim_data.n_trials                = obj.tp_main.vis_protocol.n_trials;
            obj.visstim_data.s_plus = [];
            
            if ~obj.tp_main.vis_protocol.enable_motion
                obj.visstim_data.stim_duration_s         = 30;   % for visual_only task
                obj.visstim_data.prestim_wait_s          = 0;    % for visual_only task
                obj.visstim_data.poststim_wait_s         = 10;    % for visual_only task
            else
                obj.visstim_data.stim_duration_s = [];
                obj.visstim_data.prestim_wait_s = [];
                obj.visstim_data.poststim_wait_s = [];
            end
            
            obj.visstim_data.white_val               = 1;
            obj.visstim_data.black_val               = 0;
            obj.visstim_data.grey_val                = (obj.visstim_data.white_val+obj.visstim_data.black_val)/2;
            obj.visstim_data.col_range               = abs(obj.visstim_data.white_val - obj.visstim_data.black_val)/2;
            
            % read image
            theImage = imread(obj.imagepath); 
            
            Nx = ceil(screen_size_px(1)/size(theImage,1));
            Ny = ceil(screen_size_px(2)/size(theImage,2));
            row = 1;
            for i = 1: Nx
                for j = 1: Ny
                    ImageXY(row,1) = (i-1)*size(theImage,1);
                    ImageXY(row,2) = (j-1)*size(theImage,2);
                    ImageXY(row,3) = i*size(theImage,1);
                    ImageXY(row,4) = j*size(theImage,2);
                    row = row +1;
                end
            end
            
            fprintf('settings done\n');

            %% Psychtoolbox
            Screen('Preference', 'SkipSyncTests', 2);
            PsychDefaultSetup(2); 
            
            if obj.visstim_data.apply_gamma_correction
                load(obj.visstim_data.gamma_correction_file, 'gamma_table');
                obj.visstim_data.gamma_table = gamma_table;
                obj.original_gamma_table_1 = Screen('LoadNormalizedGammaTable', 1, obj.visstim_data.gamma_table, 0);
                obj.original_gamma_table_2 = Screen('LoadNormalizedGammaTable', 2, obj.visstim_data.gamma_table, 0);
            end
            original_gamma_table_1 = obj.original_gamma_table_1;
            original_gamma_table_2 = obj.original_gamma_table_2;
            
            window = PsychImaging('OpenWindow', obj.screen_number, obj.visstim_data.grey_val, [obj.screen1_resolution(1) , 0 , 3*obj.screen234_resolution(1)+obj.screen1_resolution(1) , obj.screen234_resolution(2)]);  % modified by Yanting Yao on 25/2/2022
            Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            obj.visstim_data.s_per_frame = Screen('GetFlipInterval', window);    % ifi
            imageTexture = Screen('MakeTexture', window, theImage);
            
            if ~obj.tp_main.vis_protocol.enable_motion
                % number of frames for each part of stimulus
                obj.visstim_data.n_stim_frames = ceil(obj.visstim_data.stim_duration_s / obj.visstim_data.s_per_frame);        % for visual_only task
                obj.visstim_data.n_prestim_frames = ceil(obj.visstim_data.prestim_wait_s / obj.visstim_data.s_per_frame);      % for visual_only task
                obj.visstim_data.n_poststim_frames = ceil(obj.visstim_data.poststim_wait_s / obj.visstim_data.s_per_frame);    % for visual_only task
            else
                obj.visstim_data.n_stim_frames = [];
                obj.visstim_data.n_prestim_frames = [];
                obj.visstim_data.n_poststim_frames = [];
            end
            
            fprintf('prepare to start\n');
            obj.tp_main.tcp_server.writeline('ready');
            

            %% run visual stimulation 
            % present baseline grey screen
            Screen('FillRect', window, obj.visstim_data.grey_val);
            vbl = Screen('Flip', window);
            if KbCheck; error('escape_1'); end

            % loop through stimuli
            for stim_i = 1 : obj.visstim_data.n_trials   % start trial
        
                % wait for current trial vis_stim information from RC2
%                 lable_id = obj.tp_main.tcp_server_stimulus.readline();
                [lable_id, ~] = obj.tp_main.wait_for_rc2();             % receive current trial vis_stim lable
                obj.tp_main.vis_protocol.vis_stim_lable(lable_id);
                obj.visstim_data.s_plus(stim_i)          = obj.tp_main.vis_protocol.s_plus;
                
                fprintf('notifying RC2 of stimulus type received\n');
                obj.tp_main.tcp_server_stimulus.writeline('received');  % confirm message received
                if obj.visstim_data.s_plus(stim_i)
                    fprintf('Trial %i, stimulus: s_plus\n', stim_i);
                else
                    fprintf('Trial %i, stimulus: s_minus\n', stim_i);
                end

                % wait for trial starting message 'start_trial'
                fprintf('Trial %i, waiting for starting signal from RC2\n',stim_i);
                [message, reply_status] = obj.tp_main.wait_for_rc2();
                if reply_status == 1 && strcmp(message, 'start_trial') 
                        trial_running = false;
                        fprintf('start command received\n');
                elseif reply_status == -1   % if other computer has stopped break and cleanup
%                     sca;
                    obj.abort();  % abort and reset?
                    fprintf('stopping visual stimulus on: %i\n', stim_i);
                    break
                end
                
                if obj.tp_main.vis_protocol.enable_motion   % if is rotation + visual task,

                    while ~trial_running        % wait till trial protocol(rotation) start on RC2 ( DI0'port0/line0' is on)
                        trial_running = read(obj.tp_main.ni.d, 'Outputformat', 'Matrix');
                    end

                    %%% trial protocol start %%%

                    tocs = nan(obj.visstim_data.n_trials, 1);
                    tic();

                    while trial_running         % while DI0'port0/line0' is on, keep presenting visual_stim, till trial protocol(rotation) end on RC2 ( DI0'port0/line0' is off)

                        trial_running = read(obj.tp_main.ni.d, 'Outputformat', 'Matrix');

                        for i = 1: size(ImageXY,1)
                            Screen('DrawTexture', window, imageTexture, [ ], ImageXY(i,:), 0);
                        end
                        for pd_i = 1:length(obj.photodiode_index)
                            Screen('FillRect', window, obj.visstim_data.white_val, obj.photodiode_position(obj.photodiode_index(pd_i)).position);
                        end
                        vbl = Screen('Flip', window, vbl + 0.5*obj.visstim_data.s_per_frame);
                        
                        [~, ~, keyCode] = KbCheck;
                        if keyCode(KbName('escape')), error('escape_during_drift'), end
                        %   if KbCheck; error('escape_during_drift'); end

                    end

                    %%% trial protocol end %%%
                    tocs(stim_i) = toc();
                    fprintf('trial time: %.10f\n', tocs(stim_i));
                
                    Screen('FillRect', window, obj.visstim_data.grey_val);
                    vbl = Screen('Flip', window);
                    if KbCheck; error('escape_1'); end

                else    % if is visual_only task, 
                    % prestim
                    for frame_i = 1 : obj.visstim_data.n_prestim_frames
                        Screen('FillRect', window, obj.visstim_data.grey_val);
                        vbl = Screen('Flip', window, vbl + 0.5*obj.visstim_data.s_per_frame);
                        
                        [~, ~, keyCode] = KbCheck;
                        if keyCode(KbName('escape')), error('escape_during_isi'), end
                        %   if KbCheck; error('escape_during_isi'); end
                    end

                    %%% trial protocol start %%%
                    tocs = nan(obj.visstim_data.n_trials, 1);
                    tic();

                    for frame_i = 1 : obj.visstim_data.n_stim_frames
                        for i = 1: size(ImageXY,1)
                            Screen('DrawTexture', window, imageTexture, [ ], ImageXY(i,:), 0);
                        end
                        for pd_i = 1:length(obj.photodiode_index)
                            Screen('FillRect', window, obj.visstim_data.white_val, obj.photodiode_position(obj.photodiode_index(pd_i)).position);
                        end
                        vbl = Screen('Flip', window, vbl + 0.5*obj.visstim_data.s_per_frame);
                        
                        [~, ~, keyCode] = KbCheck;
                        if keyCode(KbName('escape')), error('escape_during_drift'), end
                        %   if KbCheck; error('escape_during_drift'); end
                    end
                    %%% trial protocol end %%%
                    tocs(stim_i) = toc();
                    fprintf('trial time: %.10f\n', tocs(stim_i));

                    % poststim
                    for frame_i = 1 : obj.visstim_data.n_poststim_frames
                        Screen('FillRect', window, obj.visstim_data.grey_val);
                        vbl = Screen('Flip', window, vbl + 0.5*obj.visstim_data.s_per_frame);
                        
                        [~, ~, keyCode] = KbCheck;
                        if keyCode(KbName('escape')), error('escape_during_isi'), end
                        %   if KbCheck; error('escape_during_isi'); end
                    end

                    obj.tp_main.tcp_server_stimulus.writeline('trial_end');     % send message that the trial has ended
                end
                
            end     % trial end
            
            %% finish experiment
            
            % post experiment baseline grey screen
            Screen('FillRect', window, obj.visstim_data.grey_val);
            vbl = Screen('Flip', window);
            if KbCheck; error('escape_1'); end
            
%             obj.save_visstim_data();
            
            % wait for ending message from RC2
            if obj.tp_main.vis_protocol.enable_motion
                [message, reply_status] = obj.tp_main.wait_for_rc2();
                if reply_status == 1 && strcmp(message, 'end_experiment') 
    %                 fprintf('end command received\n');
                elseif reply_status == -1   % if other computer has stopped break and cleanup
    %                     sca;
                    obj.abort();  % abort and reset?
                    fprintf('stopping visual stimulus on: %i\n\n', stim_i);
                end
            end
             
            fprintf('Protocol finished\n\n');
            
            % cleanup
            
        end


        function save_visstim_data(obj)
            git_version = obj.visstim_data.git_version;
            s_plus = obj.visstim_data.s_plus;
            save_fname = obj.save_fname;
            screen_number = obj.screen_number;
            screen_size_px = obj.screen_size_px;
            screen_size_mm = obj.screen_size_mm;
            apply_gamma_correction = obj.visstim_data.apply_gamma_correction;
            gamma_correction_file = obj.visstim_data.gamma_correction_file;
            distance_from_screen = obj.distance_from_screen;
            prestim_wait_s = obj.visstim_data.prestim_wait_s;
            stim_duration_s = obj.visstim_data.stim_duration_s;
            poststim_wait_s = obj.visstim_data.poststim_wait_s;
            white_val = obj.visstim_data.white_val;
            black_val = obj.visstim_data.black_val;
            grey_val = obj.visstim_data.grey_val;
            col_range = obj.visstim_data.col_range;
            imagepath = obj.imagepath;  
            n_s_plus_trials = obj.visstim_data.n_s_plus_trials;
            n_s_minus_trials = obj.visstim_data.n_s_minus_trials;
            n_trials = obj.visstim_data.n_trials;
            gamma_table = obj.visstim_data.gamma_table;
            original_gamma_table_1 = obj.original_gamma_table_1;
            original_gamma_table_2 = obj.original_gamma_table_2;
            s_per_frame = obj.visstim_data.s_per_frame;
            n_stim_frames = obj.visstim_data.n_stim_frames;
            n_prestim_frames = obj.visstim_data.n_prestim_frames;
            n_poststim_frames = obj.visstim_data.n_poststim_frames;

            vars_to_save = {'git_version'
                's_plus'
                'save_fname'
                'screen_number'
                'screen_size_px'
                'screen_size_mm'
                'apply_gamma_correction'
                'gamma_correction_file'
                'distance_from_screen'       
                'prestim_wait_s'        
                'stim_duration_s'      
                'poststim_wait_s'       
                'white_val'             
                'black_val'
                'grey_val'              
                'col_range' 
                'imagepath'              
                'n_s_plus_trials'       
                'n_s_minus_trials'      
                'n_trials' 
                'gamma_table'   
                'original_gamma_table_1'
                'original_gamma_table_2'
                's_per_frame'           
                'n_stim_frames'        
                'n_prestim_frames'      
                'n_poststim_frames'};
            
            save(obj.save_fname, vars_to_save{:});
        end


        function abort(obj)
            fprintf('Abort!\n')
            obj.cleanup();
%             obj.tp_main.reset_tcp_servers();
        end



        function cleanup(obj)
            obj.save_visstim_data();
            if ~isempty(obj.original_gamma_table_1)
                Screen('LoadNormalizedGammaTable', 1, obj.original_gamma_table_1, 0);
                Screen('LoadNormalizedGammaTable', 2, obj.original_gamma_table_2, 0);
            end
            obj.original_gamma_table_1 = [];
            obj.original_gamma_table_2 = [];
            obj.tp_main.vis_protocol = [];
            obj.tp_main.is_running = false;
            
            sca;
        end




    end
end