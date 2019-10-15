classdef Saver < handle
    
    properties
        
        is_logging = false
        
        fid
        
        ai_min_voltage = -10
        ai_max_voltage = 10
        voltage_range
    end
    
    properties (SetObservable = true)
        save_to
        prefix
        suffix
        enable = true
        index
    end
    
    
    methods
        
        function obj = Saver(config)
            obj.save_to = config.saving.save_to;
            obj.prefix = datestr(now, 'yyyymmddHHMM');
            obj.suffix = datestr(now, 'SS');
            obj.index = 0;
            
            obj.voltage_range = obj.ai_max_voltage - obj.ai_min_voltage;
        end
        
        
        function set_enable(obj, val)
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric and >= 0\n', class(obj), 'set_index');
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
                fprintf('%s: %s ''val'' must be numeric and >= 0\n', class(obj), 'set_index');
                return
            end
            if obj.is_logging; return; end
            obj.index = round(val);
        end
        
        
        function fname = logging_fname(obj)
            if obj.is_logging; return; end
            fname_ = sprintf('%s_%s_%03i.bin', obj.prefix, obj.suffix, obj.index);
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
            obj.fid = fopen(obj.logging_fname(), 'w');
            obj.is_logging = true;
        end
        
        
        function stop_logging(obj)
            if ~obj.enable; return; end
            obj.is_logging = false;
            fclose(obj.fid);
            obj.fid = [];
        end
        
        
        function log(obj, data)
            if ~obj.enable; return; end
            if ~obj.is_logging; return; end
            
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);
            fwrite(obj.fid, data(:), 'int16');
        end
    end
end