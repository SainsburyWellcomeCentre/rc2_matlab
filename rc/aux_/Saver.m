classdef Saver < handle
    
    properties
        save_to
        prefix
        suffix
        index
    end
    
    
    methods
        
        function obj = Saver(config)
            obj.save_to = config.saving.save_to;
            obj.prefix = datestr(now, 'yyyymmddHHMM');
            obj.suffix = datestr(now, 'SS');
            obj.index = 0;
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
            fname_ = sprintf('%s_%s_%03i', obj.prefix, obj.suffix, obj.index);
            fname = fullfile(obj.save_to, obj.prefix, fname_);
        end
        
        
        function create_directory(obj)
            this_dir = fullfile(obj.save_to, obj.prefix);
            if ~isdir(this_dir)
                mkdir(this_dir);
            end
        end
        
        
        function save(obj)
            obj.create_directory();
            % save config files
            obj.index = obj.index + 1;
        end
    end
end