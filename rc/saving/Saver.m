classdef Saver < handle
    
    properties (SetObservable = true)
        enable = true
        save_to
        prefix
        suffix
        index = 0
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
        index_single_trial = 0
        is_logging_single_trial = false
    end
    
    properties (Hidden = true)
        ctl
    end
    
    
    methods
        
        function obj = Saver(ctl, config)
            %TODO: remove ctl
            obj.ctl = ctl;
            obj.save_to = config.saving.save_to;
            obj.config_file = config.saving.config_file;
            obj.main_dir = config.saving.main_dir;
            obj.git_dir = config.saving.git_dir;
            obj.prefix = datestr(now, 'yyyymmddHHMM');
            obj.suffix = datestr(now, 'SS');
            
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
            obj.index = 0;
        end
        
        
        function set_prefix(obj, str)
            if obj.is_logging; return; end
            obj.prefix = str;
            obj.index = 0;
        end
        
        
        function set_suffix(obj, str)
            if obj.is_logging; return; end
            obj.suffix = str;
            obj.index = 0;
        end
        
        
        function set_index(obj, val)
            if ~isnumeric(val) || isinf(val) || isnan(val) || val < 0
                fprintf('%s: %s ''val'' must be numeric and >= 0', class(obj), 'set_index');
                return
            end
            if obj.is_logging; return; end
            obj.index = round(val);
        end
        
        
        function fname = logging_fname(obj)
            fname_ = sprintf('%s_%s_%03i.bin', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function fname = cfg_fname(obj)
            fname_ = sprintf('%s_%s_%03i.cfg', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function fname = logging_fname_single_trial(obj)
            fname_ = sprintf('%s_%s_%03i_single_trial_%03i.bin', obj.prefix, obj.suffix, obj.index, obj.index_single_trial);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function fname = cfg_fname_single_trial(obj)
            fname_ = sprintf('%s_%s_%03i_single_trial_%03i.cfg', obj.prefix, obj.suffix, obj.index, obj.index_single_trial);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function create_directory(obj)
            if obj.is_logging; return; end
            this_dir = fullfile(obj.save_to, obj.prefix);
            if ~isfolder(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        function setup_logging(obj)
            if ~obj.enable; return; end
            obj.create_directory();
            obj.index = obj.index + 1;
            obj.index_single_trial = 0;
            obj.fid = fopen(obj.logging_fname(), 'w');
            obj.save_config()
            obj.is_logging = true;
        end
        
        
        function save_config(obj)
            if ~obj.enable; return; end
            fname = sprintf('%s.cfg', obj.logging_fname());
            cfg = obj.ctl.get_config();
            obj.write_config(fname, cfg, 'w');
        end
        
        
        function stop_logging(obj)
            if ~obj.enable; return; end
            obj.is_logging = false;
            fclose(obj.fid);
            obj.fid = [];
            obj.stop_logging_single_trial();
        end
        
        
        function log(obj, data)
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);
            fwrite(obj.fid, data(:), 'int16');
            
            obj.log_single_trial(data(1, :)); %TODO:  channel to save for trial
        end
        
        
        function fname_single_trial = start_logging_single_trial(obj)
            % saving must be enabled and already logging to a main storage
            % location
            fname_single_trial = [];
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            obj.index_single_trial = obj.index_single_trial + 1;
            fname_single_trial = obj.logging_fname_single_trial();
            obj.fid_single_trial = fopen(fname_single_trial, 'w');
            disp(obj.fid_single_trial);
            obj.is_logging_single_trial = true;
        end
        
        
        function log_single_trial(obj, data)
            if ~obj.is_logging_single_trial; return; end
            if isempty(obj.fid_single_trial); return; end
            fwrite(obj.fid_single_trial, data(:), 'int16');
        end
        
        
        function stop_logging_single_trial(obj)
            if ~obj.is_logging_single_trial; return; end
            obj.is_logging_single_trial = false;
            fclose(obj.fid_single_trial);
            obj.fid_single_trial = [];
        end
        
        
        
        function write_config(obj, fname, cfg, mode)
            if ~obj.enable; return; end
            fid1 = fopen(fname, mode);
            for i = 1 : size(cfg, 1)
                fprintf(fid1, '%s = %s\n', cfg{i, 1}, cfg{i, 2});
            end
            fclose(fid1);
        end
        
    end
end