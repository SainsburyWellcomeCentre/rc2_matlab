classdef Saver < handle
    
    properties
        save_to
        prefix
        suffix
        index
        fid
        
        ai_min_voltage = -10
        ai_max_voltage = 10
        voltage_range
    end
    
    
    methods
        
        function obj = Saver(config)
            obj.save_to = config.saving.save_to;
            obj.prefix = datestr(now, 'yyyymmddHHMM');
            obj.suffix = datestr(now, 'SS');
            obj.index = 0;
            
            obj.voltage_range = obj.ai_max_voltage - obj.ai_min_voltage;
        end
        
        
        function set_save_to(obj, str)
            obj.save_to = str;
            obj.index = 0;
        end
        
        
        function set_prefix(obj, str)
            obj.prefix = str;
            obj.index = 0;
        end
        
        
        function set_suffix(obj, str)
            obj.suffix = str;
            obj.index = 0;
        end
        
        
        function fname = logging_fname(obj)
            fname_ = sprintf('%s_%s_%03i.bin', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function create_directory(obj)
            this_dir = fullfile(obj.save_to, obj.prefix);
            if ~isfolder(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        function setup_logging(obj)
            obj.create_directory();
            obj.index = obj.index + 1;
            obj.fid = fopen(obj.logging_fname(), 'w');
        end
        
        
        function stop_logging(obj)
            fclose(obj.fid);
            obj.fid = [];
        end
        
        
        function log(obj, data)
            data = int16(-2^15 + ((data' - obj.ai_min_voltage)/obj.voltage_range)*2^16);
            fwrite(obj.fid, data(:), 'int16');
        end
    end
end