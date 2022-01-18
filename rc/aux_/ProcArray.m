classdef ProcArray < handle
% ProcArray Class for storing a set of process objects (c.f. ProcHandler).
%
%   ProcArray Properties:
%       processes           - cell array of ProcHandler objects
%
%   ProcArray Methods:
%       add_process         - adds a process to the array
%       clear_all           - kills all processes in the array
    
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
        %%add_process Adds a process to the array
        %
        %   add_process(PROC) adds a ProcHandler object in PROC to the
        %   `processes` array.
        
            obj.processes{end+1} = proc;
        end
        
        
        function clear_all(obj)
        %%clear_all Kills all processes in the `processes` array
        %
        %   clear_all() 
        
            for i = 1 : length(obj.processes)
                obj.processes{i}.kill()
            end
        end
    end
end