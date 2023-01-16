classdef Saver < handle
    % Saver class for handling logging of data and configurations.

    properties (SetObservable = true)
        enable = true % Boolean specifying whether class is enabled and will save during acquisition.
        save_to % Top directory for saving.
        prefix % Prefix to apply to each saved file.
        suffix % Suffix to apply to each saved file.
        index = 1 % Index to apply to each saved file.
    end
    
    properties (SetAccess = private, Hidden = true)
        config_file % Full path to the original configuration file.
        main_dir % Full path to the rollercoaster directory.
        git_dir % Full path to the .git directory for rollercoaster.
        fid % Current file identifier.
        is_logging = false % Boolean indicating whether class is currently saving.
        ai_min_voltage = -10 % Minimum analog input voltage, mapped to -2^15 (int16).
        ai_max_voltage = 10 % Maximum analog input voltage, mapped to 2^15-1 (int16).
        voltage_range % Total voltage range.
        fid_single_trial % File identifier for saving a single trial.
        single_trial_log_channel_idx = 1 % Index of the analog input to save when logging data for a single trial.
        is_logging_single_trial = false % Boolean indicating whether class is currently saving a single trial.
    end
    
    properties (SetAccess = private, Hidden = true)
        ctl % Handle to :class:`RC2Controller`
    end
    
    
    
    methods
        function obj = Saver(ctl, config)
            % Constructor for a :class:`rc.classes.Saver`.
            % Saver(ctl, config) creates object to deal with logging data and
            % saving config information.
            %
            % :param ctl: A :class:`rc.main.RC2Controller` object.
            % :param config: The main configuration structure.
        
            obj.enable = config.saving.enable;
            if ~obj.enable, return, end
            
            obj.ctl = ctl;
            obj.save_to = config.saving.save_to;
            obj.config_file = config.saving.config_file;
            obj.main_dir = config.saving.main_dir;
            obj.git_dir = config.saving.git_dir;
            obj.prefix = datestr(now, 'yyyymmddHHMM');
            obj.suffix = datestr(now, 'SS');
            
            if isfield(config.saving, 'single_trial_log_channel_name')
                obj.set_single_trial_log_channel(config.saving.single_trial_log_channel_name);
            end
            
            obj.voltage_range = obj.ai_max_voltage - obj.ai_min_voltage;
        end
           
        
        function set_enable(obj, val)
            % Set :attr:`enable` property.
            %
            % :param val: Boolean specifying enabled status - whether to save data during acquisition.
        
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric and >= 0', class(obj), 'set_index');
                return
            end
            
            if obj.is_logging; return; end
            
            obj.enable = logical(val);
        end
        
        
        function set_save_to(obj, str)
            % Set :attr:`save_to` property. Also resets the :attr:`index` property to 1.
            % Data are saved in files of format :attr:`save_to`/:attr:`prefix`/:attr:`prefix` _ :attr:`suffix` _ :attr:`index`.bin
            %
            % :param str: String representing full path to a directory in which to log data and config info.
        
            if obj.is_logging; return; end
            obj.save_to = str;
            obj.index = 1;
        end
        
        
        function set_prefix(obj, str)
            % Set the :attr:`prefix` property.
            % Data are saved in files of format :attr:`save_to`/:attr:`prefix`/:attr:`prefix` _ :attr:`suffix` _ :attr:`index`.bin
            %
            % :param str: String representing the desired prefix.
        
            if obj.is_logging; return; end
            obj.prefix = str;
            obj.index = 1;
        end
        
        
        function set_suffix(obj, str)
            % Set the :attr:`suffix` property.
            % Data are saved in files of format :attr:`save_to`/:attr:`prefix`/:attr:`prefix` _ :attr:`suffix` _ :attr:`index`.bin
            %
            % :param str: String representing the desired suffix.
        
            if obj.is_logging; return; end
            obj.suffix = str;
            obj.index = 1;
        end
        
        
        function set_index(obj, val)
            % Set the :attr:`index` property.
            % Data are saved in files of format :attr:`save_to`/:attr:`prefix`/:attr:`prefix` _ :attr:`suffix` _ :attr:`index`.bin
            % 
            % :param str: Integer representing the desired index.
        
            if ~isnumeric(val) || isinf(val) || isnan(val) || val < 1
                fprintf('%s: %s ''val'' must be numeric and >= 1', class(obj), 'set_index');
                return
            end
            
            if obj.is_logging; return; end
            obj.index = round(val);
        end
        
        
        
        function str = save_root_name(obj)
            % Get the file name of the saving directory.
            %
            % :return: File name of the saving directory.

            str = sprintf('%s_%s_%03i', obj.prefix, obj.suffix, obj.index);
        end
        
        
        function str = save_fulldir(obj)
            % Get the full path to the saving directory.
            %
            % :return: Full path to the saving directory.

            str = fullfile(obj.save_to, obj.prefix);
        end

        
        
        function set_single_trial_log_channel(obj, channel_name)
            % Set the :attr:`single_trial_log_channel_idx` property.
            %
            % :param channel_name: String representing an analog input channel name. If no matching channel can be found :attr:`single_trial_log_channel_idx` defaults to 1.
        
            idx = find(strcmp(obj.ctl.ni.ai.channel_names, channel_name));
            
            if isempty(idx)
                obj.single_trial_log_channel_idx = 1;
                warning('Channel name `%s` not found, logging first channel on the analog input', ...
                        channel_name);
            else
                obj.single_trial_log_channel_idx = idx;
            end
        end
        
        
        function fname = logging_fname(obj)
            % Get the full path to the logging .bin file.
            %
            % :return: Full path to the logging .bin file.
        
            fname_ = sprintf('%s_%s_%03i.bin', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function fname = cfg_fname(obj)
            % Get the full path to the configuration .cfg file.
            %
            % :return: Full path to configuration .cfg file.
        
            fname_ = sprintf('%s_%s_%03i.cfg', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
%         function fname = logging_fname_single_trial(obj)
%             fname_ = sprintf('%s_%s_%03i_single_trial_%03i.bin', obj.prefix, obj.suffix, obj.index, obj.index_single_trial);
%             fname = fullfile(obj.save_to, obj.prefix, fname_);
%         end
        

%         function fname = cfg_fname_single_trial(obj)
%             fname_ = sprintf('%s_%s_%03i_single_trial_%03i.cfg', obj.prefix, obj.suffix, obj.index, obj.index_single_trial);
%             fname = fullfile(obj.save_to, obj.prefix, fname_);
%         end
        

        function create_directory(obj)
            % Create directory to save .bin files of the form :attr:`save_to`/:attr:`prefix`
        
            if obj.is_logging; return; end
            
            this_dir = fullfile(obj.save_to, obj.prefix);
            
            if ~isfolder(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        function setup_logging(obj)
            % Prepare for logging of data to a file. Checks for existence of a saving .bin or .cfg file
            % and asks user whether to overwrite. Creates any necessary directories, creates a stream to a .bin file
            % and saves the configuration information.
        
            % if saving is not enabled, do nothing
            if ~obj.enable; return; end
            
            % check  to make sure the file doesn't already exist
            if exist(obj.logging_fname(), 'file')
                uans = questdlg('File already exists. Overwrite?', 'File warning', 'Yes', 'No', 'No');
                if strcmp(uans, 'No')
                    error('File already exists. Aborting.')
                end
            end
            
            % create the right directory
            obj.create_directory();
            
            % open the file for writing
            obj.fid = fopen(obj.logging_fname(), 'w');
            
            % save the config file
            obj.save_config()
            
            % set the is_logging flag to true
            obj.is_logging = true;
        end
        
        
        function save_config(obj)
            % Save the setup configuration .cfg file along with the .bin file. 
        
            if ~obj.enable; return; end
            
            fname = obj.cfg_fname();
            
            cfg = obj.ctl.get_config();
            
            obj.write_config(fname, cfg, 'w');
        end
        
        
        function append_config(obj, cfg)
            % Append configuration information to the .cfg file.
            %
            % :param cfg: The configuration information to append, should be Nx2 cell array with each row as a {<key>, <value>}.
        
            if ~obj.enable; return; end
            
            fname = obj.cfg_fname();
            obj.write_config(fname, cfg, 'a');
        end
        
        
        function stop_logging(obj)
            % Stop logging data. Closes the .bin file stream and stops any other single file logging streams. Also iterates the :attr:`index` property.
        
            if ~obj.enable; return; end
            
            obj.index = obj.index + 1;
            
            obj.is_logging = false;
            
            fclose(obj.fid);
            
            obj.fid = [];
            
            obj.stop_logging_single_trial();
        end
        
        
        function log(obj, data)
            % Log data from AI task to a .bin file. Data should be passed to this method from AI callbacks. Transformed data will be stored in the file opened with :meth:`setup_logging`.
            %
            % :param data: Data to be logged. This method scales the input data into int16 values. If :attr:`is_logging_single_trial` is true :meth:`log_single_trial` will be called.
        
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);
            
            fwrite(obj.fid, data(:), 'int16');
            
            single_trial_data = data(obj.single_trial_log_channel_idx, :);
            
            obj.log_single_trial(single_trial_data);
        end
        
        
        function fid = start_logging_single_trial(obj, fname)
            % Prepare for logging of data from single trials.
            %
            % :param fname: Path for save file.
            % :return: File identifier for save file.
        
            % saving must be enabled and already logging to a main storage
            % location
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            % do not start another one if already logging single trial
            if obj.is_logging_single_trial; return; end
            
            % open file
            fid = fopen(fname, 'w');
            
            % return if file couldn't be opened
            if fid == -1
                return
            end
            
            % store for use
            obj.fid_single_trial = fid;
            
            % switch on logging flag
            obj.is_logging_single_trial = true;
        end
        
        
        function log_single_trial(obj, data)
            % Log data in single trial to .bin file.
            %
            % :param data: Single trial data.
        
            if ~obj.is_logging_single_trial; return; end
            if isempty(obj.fid_single_trial); return; end
            
            % write the data
            fwrite(obj.fid_single_trial, data(:), 'int16');
        end
        
        
        function stop_logging_single_trial(obj)
            % Stop logging single trial data. Closes the file for single trial data.
        
            if ~obj.is_logging_single_trial; return; end
            
            % switch off the logging flag
            obj.is_logging_single_trial = false;
            % close the file
            fclose(obj.fid_single_trial);
            % clear the file id
            obj.fid_single_trial = [];
        end
        
        
        function write_config(obj, fname, cfg, mode)
            % Write to the configuration file.
            %
            % :param fname: The full path of the output file.
            % :param cfg: Nx2 cell array containing the config information.
            % :param mode: Char specifying `fopen <https://uk.mathworks.com/help/matlab/ref/fopen.html>`_ mode. 'w' will overwrite an existing file, 'a' will append the data to the file.
        
            if ~obj.enable; return; end
            
            fid1 = fopen(fname, mode);
            
            for i = 1 : size(cfg, 1)
                fprintf(fid1, '%s = %s\n', cfg{i, 1}, cfg{i, 2});
            end
            fprintf(fid1, '\n\n\n');
            
            fclose(fid1);
        end
    end
end
