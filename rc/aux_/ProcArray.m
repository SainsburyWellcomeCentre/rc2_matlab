classdef ProcArray < handle
    % ProcArray class for storing a set of process objects :class:`rc.aux_.ProcHandler`.
    
    properties (SetAccess = private)
        processes = {} % Cell array of :class:`rc.aux_.ProcHandler` objects.
    end
    
    
    methods    
        function obj = ProcArray()
            % Constructor for a :class:`rc.aux_.ProcArray` class.
            %
            % TODO - Along with ProcHandler, want to find a better solution.
        end
        
        
        function add_process(obj, proc)
            % Adds a process to the :attr:`processes` array.
            %
            % :param proc: The :class:`rc.aux_.ProcHandler` to add.
        
            obj.processes{end+1} = proc;
        end
        
        
        function clear_all(obj)
            % Kills all processes in the :attr:`processes` array.
        
            for i = 1 : length(obj.processes)
                obj.processes{i}.kill()
            end
        end
    end
end