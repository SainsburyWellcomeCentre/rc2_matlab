classdef vis_stim_Off < handle

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
        
        
        photodiode_1_position
        photodiode_2_position
        photodiode_3_position
        distance_from_screen
    end




    methods

        function obj = vis_stim_Off()

            obj.screen1_resolution      = [2560,1440];
            obj.screen234_resolution    = [1280,720];  % 
            obj.screen_number           = 1;                % index of combined screen
            obj.screen_size_px          = [3840,720];
            obj.screen_size_mm          = [345, 195];
            
            photodiode_zone = 200;
            obj.photodiode_1_position   = [0, 0, photodiode_zone, photodiode_zone];
            obj.photodiode_2_position   = [obj.screen234_resolution(1), 0, obj.screen234_resolution(1)+photodiode_zone, photodiode_zone];
            obj.photodiode_3_position   = [3*obj.screen234_resolution(1)-photodiode_zone 0, 3*obj.screen234_resolution(1), photodiode_zone];
            obj.distance_from_screen    = 100;
            
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

            obj.visstim_data.white_val               = 1;
            obj.visstim_data.black_val               = 0;
            obj.visstim_data.grey_val                = (obj.visstim_data.white_val+obj.visstim_data.black_val)/2;
            obj.visstim_data.col_range               = abs(obj.visstim_data.white_val - obj.visstim_data.black_val)/2;
            obj.visstim_data.solidfill_color         = [0,0,0]; 
        
            fprintf('settings done\n');

            % loop through stimuli
            for stim_i = 1 : obj.visstim_data.n_trials   % start trial

                fprintf('Trial %i, visstim off\n', stim_i);

                % wait for trial starting message 'start_trial'
                fprintf('Trial %i, waiting for starting signal from RC2\n',stim_i);
                [message, reply_status] = obj.tp_main.wait_for_rc2();
                if reply_status == 1 && strcmp(message, 'start_trial') 
                        fprintf('start command received\n');
                else
                    obj.abort();  % abort and reset?
                    fprintf('stopping visual stimulus on: %i\n', stim_i);
                    return
                end

                %%% trial protocol start %%%
%                 pause(30);
                %%% trial protocol end %%%

                % poststim
%                 pause(10);

                [message, reply_status] = obj.tp_main.wait_for_rc2();
                if reply_status == 1 && strcmp(message, 'end_trial')
                        fprintf('end command received\n');
                else
                    obj.abort();  % abort and reset?
                    fprintf('stopping visual stimulus on: %i\n', stim_i);
                    return
                end  
            end     % trial end
            
            %% finish experiment

            % wait for ending message from RC2
            [message, reply_status] = obj.tp_main.wait_for_rc2();
            if reply_status == 1 && strcmp(message, 'end_experiment') 
            else
                obj.abort();  % abort and reset?
                fprintf('stopping visual stimulus on: %i\n\n', stim_i);
                return
            end

             
            fprintf('Protocol finished\n\n');
            
            % cleanup
            
        end


        function save_visstim_data(obj)
            git_version = obj.visstim_data.git_version;
%             s_plus = obj.visstim_data.s_plus;
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
            solidfill_color = obj.visstim_data.solidfill_color;  
            n_s_plus_trials = obj.visstim_data.n_s_plus_trials;
            n_s_minus_trials = obj.visstim_data.n_s_minus_trials;
            n_trials = obj.visstim_data.n_trials;
            original_gamma_table_1 = obj.original_gamma_table_1;
            gamma_table = obj.visstim_data.gamma_table;
            original_gamma_table_2 = obj.original_gamma_table_2;
            s_per_frame = obj.visstim_data.s_per_frame;
            n_stim_frames = obj.visstim_data.n_stim_frames;
            n_prestim_frames = obj.visstim_data.n_prestim_frames;
            n_poststim_frames = obj.visstim_data.n_poststim_frames;

            vars_to_save = {'git_version'
%                 's_plus'
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
                'solidfill_color'              
                'n_s_plus_trials'       
                'n_s_minus_trials'      
                'n_trials'                         
                'original_gamma_table_1'
                'gamma_table'           
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
%             obj.save_visstim_data();
            if ~isempty(obj.original_gamma_table_1)
                Screen('LoadNormalizedGammaTable', 1, obj.original_gamma_table_1, 0);
                Screen('LoadNormalizedGammaTable', 2, obj.original_gamma_table_2, 0);
            end
            obj.original_gamma_table_1 = [];
            obj.original_gamma_table_2 = [];
            obj.tp_main.vis_protocol = [];
            obj.tp_main.is_running = false;

        end


    end
end