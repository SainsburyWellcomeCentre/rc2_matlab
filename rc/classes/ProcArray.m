classdef ProcArray < handle
    
    properties (SetAccess = private)
        
        processes = {}
    end
    
    
    
    methods
        
        function obj = ProcArray()
        %obj = PROCARRAY()
        %   Class for storing a set of process objects (ProcHandler). 
        %   Can run obj.add_process(proc) to add a process and obj.clear_all() 
        %   to kill all of the processes at the same time...
        %
        %   Along with ProcHandler, want to find a better solution.
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