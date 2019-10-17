classdef ProcArray < handle
    
    properties
        processes = {}
    end
    
    methods
        
        function obj = ProcArray()
        end
        
        
        function add_process(obj, proc)
            obj.processes{end+1} = proc;
        end
        
        function clear_all(obj)
            for i = 1 : length(obj.processes)
                obj.processes{i}.kill()
            end
        end
    end
end