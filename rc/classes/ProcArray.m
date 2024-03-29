classdef ProcArray < handle
    % ProcArray class for storing a set of process objects :class:`rc.classes.ProcHandler`.
    
    properties (SetAccess = private)
        processes = {} % Cell array of :class:`rc.classes.ProcHandler` objects.
    end
    
    
    methods    
        function obj = ProcArray()
            % Constructor for a :class:`rc.classes.ProcArray` class.
            %
            % TODO - Along with ProcHandler, want to find a better solution.
        end
        
        
        
        function add_process(obj, proc)
            % Adds a process to the :attr:`processes` array.
            %
            % :param proc: The :class:`rc.classes.ProcHandler` to add.
        
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
