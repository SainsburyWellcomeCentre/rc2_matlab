classdef Saver < handle
% Saver Class for handling logging of data and configurations
%
%   Saver Properties:
%       enabled         - whether to use this module
%       save_to         - top directory in which saving is occurring
%       prefix          - prefix to apply to each saved file
%       suffix          - suffix to apply to each saved file
%       index           - index to apply to each saved file
%       config_file     - full path to the original configuration file
%       main_dir        - full path to the rollercoaster directory
%       git_dir         - full path to the .git directory for rollercoaster
%       fid             - current file identifier
%       is_logging      - boolean, are we currently saving data
%       ai_min_voltage  - minimum voltage, mapped to -2^15 (int16)
%       ai_max_voltage  - maximum voltage, mapped to 2^15-1 (int16)
%       voltage_range   - total voltage range
%       fid_single_trial    - file identifier to file where single trial is
%                             being saved
%       single_trial_log_channel_idx - index of the analog input to save
%                                      when logging data for a single trial
%       is_logging_single_trial - boolean, are we currently saving a
%                                 single trial
%       ctl                 - object of class RC2Controller
%
%   Saver Methods:
%       set_enable      - set `enable` property
%       set_save_to     - set the `save_to` property
%       set_prefix      - set the `prefix` property
%       set_suffix      - set the `suffix` property
%       set_index       - set the `index` property
%       set_single_trial_log_channel - set the `single_trial_log_channel_idx` 
%                                      property by using the name of an
%                                      analog input
%       logging_fname   - return the full path to the current logging .bin file
%       cfg_fname       - return the full path to the current configuration .cfg file
%       create_directory - create the directory in which to put the .bin files
%       setup_logging   - prepare for logging of data to a file
%       save_config     - save the setup configuration along with the .bin file
%       append_config   - append configuration information to the config file
%       stop_logging    - stop logging data
%       log             - log data to .bin file
%       start_logging_single_trial  - prepare for logging of data for single trials
%       log_single_trial            - log data in single trial to .bin file
%       stop_logging_single_trial   - stop logging data in single trial
%       write_config    - write to the config file
%
%   Data are saved to files of the form:
%       <save_to>\<prefix>\<prefix_suffix_index>.bin
%   and associated config files are of the form:
%       <save_to>\<prefix>\<prefix_suffix_index>.cfg

    properties (SetObservable = true)
        
        enable = true
        save_to
        prefix
        suffix
        index = 1
    end
    
    properties (SetAccess = private, Hidden = true)
        
        config_file
        main_dir
        git_dir
        
        fid
        is_logging = false
        ai_min_voltage = -10
        ai_max_voltage = 10
        voltage_range
        
        fid_single_trial
        single_trial_log_channel_idx = 1
        is_logging_single_trial = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = Saver(ctl, config)
        % Saver
        %
        %   Saver(CTL, CONFIG) creates object to deal with logging data and
        %   saving config information. CTL is an object of class
        %   Controller/RC2Controller, and CONFIG is a structure containing
        %   the setup configuration information at startup.
        
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
        %%set_enable Set `enable` property
        %
        %   set_enable(VALUE) sets `enable` to VALUE which should be a
        %   boolean, true or false, and determines whether to save data
        %   during acquisition.
        
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric and >= 0', class(obj), 'set_index');
                return
            end
            
            if obj.is_logging; return; end
            
            obj.enable = logical(val);
        end
        
        
        
        function set_save_to(obj, str)
        %%set_save_to Set the `save_to` property
        %
        %   set_save_to(STRING) sets the `save_to` property to STRING,
        %   which should be a full path to a directory in which to log data
        %   and config info. Also resets the `index` property to 1.
        %
        %   Data are saved in files of format:
        %       <save_to>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_prefix, set_suffix, set_index
        
            if obj.is_logging; return; end
            obj.save_to = str;
            obj.index = 1;
        end
        
        
        
        function set_prefix(obj, str)
        %%set_prefix Set the `prefix` property
        %
        %   set_prefix(STRING) sets the `prefix` property to STRING. 
        %
        %   Data are saved in files of format:
        %       <save_to>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_to, set_suffix, set_index
        
            if obj.is_logging; return; end
            obj.prefix = str;
            obj.index = 1;
        end
        
        
        
        function set_suffix(obj, str)
        %%set_suffix Set the `suffix` property
        %
        %   set_suffix(STRING) sets the `suffix` property to STRING. 
        %
        %   Data are saved in files of format:
        %       <save_to>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_to, set_prefix, set_index
        
            if obj.is_logging; return; end
            obj.suffix = str;
            obj.index = 1;
        end
        
        
        
        function set_index(obj, val)
        %%set_index Set the `index` property
        %
        %   set_index(VALUE) sets the `index` property to VALUE. 
        %
        %   Data are saved in files of format:
        %       <save_to>\<prefix>\<prefix_suffix_index>.bin
        %
        %   See also: set_save_to, set_prefix, set_suffix
        
            if ~isnumeric(val) || isinf(val) || isnan(val) || val < 1
                fprintf('%s: %s ''val'' must be numeric and >= 1', class(obj), 'set_index');
                return
            end
            
            if obj.is_logging; return; end
            obj.index = round(val);
        end
        
        
        
        function str = save_root_name(obj)
            str = sprintf('%s_%s_%03i', obj.prefix, obj.suffix, obj.index);
        end
        
        
        function str = save_fulldir(obj)
            str = fullfile(obj.save_to, obj.prefix);
        end

        
        
        function set_single_trial_log_channel(obj, channel_name)
        %%set_single_trial_log_channel Set the channel to save when saving
        %%single trial data.
        %
        %   set_single_trial_log_channel(CHANNEL_NAME) takes a string in
        %   CHANNEL_NAME matching one of the analog inputs and sets the
        %   `single_trial_log_channel_idx` property. If no such channel
        %   name is found, `single_trial_log_channel_idx` is set to 1 (the
        %   first analog input.
        
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
        %%logging_fname Return the full path to the logging .bin file
        %
        %   FILENAME = logging_fname() takes the `save_to`, `prefix`,
        %   `suffix` and `index` properties and creates the full path to a
        %   .bin file in which to save data.
        
            fname_ = sprintf('%s_%s_%03i.bin', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        
        function fname = cfg_fname(obj)
        %%cfg_fname Return the full path to the configuration .cfg file
        %
        %   FILENAME = cfg_fname() takes the `save_to`, `prefix`,
        %   `suffix` and `index` properties and creates the full path to a
        %   .cfg file in which to save config information.
        
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
        %%create_directory Create the directory in which to put the .bin
        %%files
        %
        %   create_directory() creates the directory in which to put the
        %   .bin file. This is of the form:
        %   <save_to>\<prefix>\
        %
        %   See also: set_save_to, set_prefix
        
        
            if obj.is_logging; return; end
            
            this_dir = fullfile(obj.save_to, obj.prefix);
            
            if ~isfolder(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        
        function setup_logging(obj)
        %%setup_logging Prepare for logging of data to a file
        %
        %   setup_logging() is the main function for setting up before
        %   saving to a .bin/.cfg file. Checks for existance of file and
        %   asks user whether to overwrite. Creates any necessary
        %   directories. Opens a stream to a bin file and saves the
        %   configuration information.
        
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
        %%save_config Save the setup configuration along with the .bin file
        %
        %   save_config() save the setup configuration to a .cfg file.
        %
        %   See also: cfg_fname, RC2Controller.get_config()
        
            if ~obj.enable; return; end
            
            fname = obj.cfg_fname();
            
            cfg = obj.ctl.get_config();
            
            obj.write_config(fname, cfg, 'w');
        end
        
        
        function append_config(obj, cfg)
        %%append_config Append configuration information to the config file
        %
        %   append_config(CONFIG) appends the configuration information in
        %   CONFIG to the main .cfg file. CONFIG is a Nx2 cell array
        %   with each row of the form {<key>, <value>}, and is saved in the
        %   file as:
        %       key=value
        %   
        %   See also: RC2Controller.get_config
        
            if ~obj.enable; return; end
            
            fname = obj.cfg_fname();
            obj.write_config(fname, cfg, 'a');
        end
        
        
        
        function stop_logging(obj)
        %%stop_logging Stop logging data
        %
        %   stop_logging() closes the .bin file stream and stops any other
        %   logging streams (for single files). It also iterates the
        %   `index` property.
        
            if ~obj.enable; return; end
            
            obj.index = obj.index + 1;
            
            obj.is_logging = false;
            
            fclose(obj.fid);
            
            obj.fid = [];
            
            obj.stop_logging_single_trial();
        end
        
        
        
        function log(obj, data)
        %%log Log data to .bin file
        %
        %   log(DATA) performs the logging of voltage data from the AI. On
        %   each AI callback, data is passed to this function and it is
        %   stored in the file opened with `setup_logging`. The data is
        %   first scaled into int16 values, and then stored as int16
        %   integers. Further, if logging of single trials is on, it will
        %   call the `log_single_trial` method.
        %
        %   See also: setup_logging
        
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);
            
            fwrite(obj.fid, data(:), 'int16');
            
            single_trial_data = data(obj.single_trial_log_channel_idx, :);
            
            obj.log_single_trial(single_trial_data);
        end
        
        
        
        function fid = start_logging_single_trial(obj, fname)
        %%start_logging_single_trial Prepare for logging of data for single
        %%trials
        %
        %   FID = start_logging_single_trial(FILENAME) sets up the logging
        %   of a single trial. 
        
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
        %%log_single_trial Log data in single trial to .bin file
        %
        %   log_single_trial(DATA) log data to the single trial .bin file.
        
            if ~obj.is_logging_single_trial; return; end
            if isempty(obj.fid_single_trial); return; end
            
            % write the data
            fwrite(obj.fid_single_trial, data(:), 'int16');
        end
        
        
        
        function stop_logging_single_trial(obj)
        %%stop_logging_single_trial Stop logging data in single trial
        %
        %   stop_logging_single_trial() closes the file for single trial
        %   data.
        
            if ~obj.is_logging_single_trial; return; end
            
            % switch off the logging flag
            obj.is_logging_single_trial = false;
            % close the file
            fclose(obj.fid_single_trial);
            % clear the file id
            obj.fid_single_trial = [];
        end
        
        
        
        function write_config(obj, fname, cfg, mode)
        %%write_config Write to the config file
        %
        %   write_config(FILENAME, CONFIG, MODE) writes configuration
        %   information to a file. FILENAME is the full path to a file to
        %   write to. CONFIG is the N x 2 cell array containing the config
        %   information. MODE is either 'w' or 'a' (see fopen). 'w' will
        %   overwrite the file if it exists, 'a' will append the data to
        %   the file.
        %
        %   See also: RC2Controller.get_config
        
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
