classdef Saver_DoubleRotation < handle
    
    properties (SetObservable = true)
        enable = true
        save_to
        prefix  % Animal ID
        suffix  % Session
        index   % Protocol
        filename
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
        is_logging_single_trial = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = Saver_DoubleRotation(ctl, config)
            obj.enable = config.saving.enable;
            if ~obj.enable, return, end
            
            %TODO: remove ctl
            obj.ctl = ctl;
            obj.save_to = config.saving.save_to;
            obj.config_file = config.saving.config_file;
            obj.main_dir = config.saving.main_dir;
            obj.git_dir = config.saving.git_dir;
            obj.prefix = 'animal';
            obj.suffix = 'session';
            obj.index = '';
            obj.filename = '';
%             obj.prefix = datestr(now, 'yyyymmddHHMM');
%             obj.suffix = datestr(now, 'SS');
%             obj.index = 1;
            
            obj.voltage_range = obj.ai_max_voltage - obj.ai_min_voltage;
        end
        
        
        function set_enable(obj, val)
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric and >= 0', class(obj), 'set_index');
                return
            end
            if obj.is_logging; return; end
            
            obj.enable = logical(val);
        end
        
        
        function set_save_to(obj, str)
            if obj.is_logging; return; end
            obj.save_to = str;
%             obj.index = 1;
        end
        
        
        function set_prefix(obj, str)
            if obj.is_logging; return; end
            obj.prefix = str;
%             obj.index = 1;
        end
        
        
        function set_suffix(obj, str)
            if obj.is_logging; return; end
            obj.suffix = str;
%             obj.index = 1;
        end
        
        function set_index(obj, str)
            if obj.is_logging; return; end
            obj.index = str;
        end
        %{
        function set_index(obj, val)
            if ~isnumeric(val) || isinf(val) || isnan(val) || val < 1
                fprintf('%s: %s ''val'' must be numeric and >= 1', class(obj), 'set_index');
                return
            end
            if obj.is_logging; return; end
            obj.index = round(val);
        end
        %}
        
        function set_filename(obj, str)
            if obj.is_logging; return; end
            obj.filename = str;
        end
        
        function str = save_root_name(obj)
            str = sprintf('%s_%s_%s', obj.prefix, obj.suffix, obj.index);
        end
        
        
        function str = save_fulldir(obj)
            str = fullfile(obj.save_to, obj.prefix);
        end
        
        
        
        function fname = logging_fname(obj)
            fname_ = sprintf('%s_%s_%s.bin', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function fname = cfg_fname(obj)
            fname_ = sprintf('%s_%s_%s.cfg', obj.prefix, obj.suffix, obj.index);
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
            if obj.is_logging; return; end
            this_dir = fullfile(obj.save_to, obj.prefix);
            if ~isfolder(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        function setup_logging(obj)
            
            % if saving is not enabled, do nothing
            if ~obj.enable; return; end
            
            % check  to make sure the file doesn't already exist
            if exist(obj.logging_fname(), 'file')
                uans = questdlg('File already exists. Overwrite?', 'File warning', 'Yes', 'No', 'No');
                if strcmp(uans, 'No')
                    error('File already exists. Aborting.')
                end
            end
            
            % create the right directory  创建正确的目录
            obj.create_directory();
            
            % open the file for writing
            obj.fid = fopen(obj.logging_fname(), 'w');   % 打开文件filename以便以二进制读取形式进行访问，并返回等于或大于3的整数文件标识符
            
            % save the config file
            obj.save_config()           % 将NIDAQ采样配置信息config保存到.cfg文件
            
            % set the is_logging flag to true
            obj.is_logging = true;
        end
        
        
        function save_config(obj)
            if ~obj.enable; return; end
            fname = obj.cfg_fname();
            cfg = obj.ctl.get_config();
            obj.write_config(fname, cfg, 'w');
        end
        
        
        function append_config(obj, cfg)
            if ~obj.enable; return; end
            fname = obj.cfg_fname();
            obj.write_config(fname, cfg, 'a');
        end
        
        
        function stop_logging(obj)
            if ~obj.enable; return; end
%             obj.index = obj.index + 1;
            obj.is_logging = false;
            fclose(obj.fid);
            obj.fid = [];
            obj.stop_logging_single_trial();
        end
        
        
        function log(obj, data)                % 将NIDAQ采集的单位数据转换为int16整型，并写入.bin文件
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);  % 将电压数据转化为int16整型
            fwrite(obj.fid, data(:), 'int16');  % 按照'int16'格式将data中的值写入.bin文件。obj.fid为文件标识符
            
            obj.log_single_trial(data(1, :)); %TODO:  channel to save for trial
        end
        
        
        function fid = start_logging_single_trial(obj, fname)
            
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
            
            if ~obj.is_logging_single_trial; return; end
            if isempty(obj.fid_single_trial); return; end
            
            % write the data
            fwrite(obj.fid_single_trial, data(:), 'int16');
        end
        
        
        function stop_logging_single_trial(obj)
            
            if ~obj.is_logging_single_trial; return; end
            
            % switch off the logging flag
            obj.is_logging_single_trial = false;
            % close the file
            fclose(obj.fid_single_trial);
            % clear the file id
            obj.fid_single_trial = [];
        end
        
        
        
        function write_config(obj, fname, cfg, mode)
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
