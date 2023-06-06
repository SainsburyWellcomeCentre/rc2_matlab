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
        distance_from_screen
        
    end




    methods

        function obj = vis_stim_Off(config)

            obj.screen1_resolution      = config.screen.screen1_resolution;
            obj.screen234_resolution    = config.screen.screen234_resolution;
            obj.screen_number           = config.screen.screen_number;          % index of combined screen
            obj.screen_size_px          = config.screen.screen_size_px;
            obj.screen_size_mm          = config.screen.screen_size_mm;
            obj.distance_from_screen    = config.screen.distance_from_screen;
            
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
            white_val = obj.visstim_data.white_val;
            black_val = obj.visstim_data.black_val;
            grey_val = obj.visstim_data.grey_val;
            col_range = obj.visstim_data.col_range;
            n_s_plus_trials = obj.visstim_data.n_s_plus_trials;
            n_s_minus_trials = obj.visstim_data.n_s_minus_trials;
            n_trials = obj.visstim_data.n_trials;
            original_gamma_table_1 = obj.original_gamma_table_1;
            gamma_table = obj.visstim_data.gamma_table;
            original_gamma_table_2 = obj.original_gamma_table_2;

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
                'n_s_plus_trials'       
                'n_s_minus_trials'      
                'n_trials'                         
                'original_gamma_table_1'
                'gamma_table'           
                'original_gamma_table_2'};
            
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