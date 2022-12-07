classdef ProcHandler < handle
    % ProcHandler class for loose wrapper around a MATLAB `java.lang.Process <https://docs.oracle.com/javase/8/docs/api/java/lang/Process.html>`_.

    properties (SetAccess = private)
        proc % The `java.lang.Process <https://docs.oracle.com/javase/8/docs/api/java/lang/Process.html>`_ object.
    end
    
    
    
    methods
        
        function obj = ProcHandler(proc)
            % Constructor for a :class:`rc.aux_.ProcHandler` class.
            % TODO - Along with ProcArray, want to find a better solution.
            %
            % :param proc: A `java.lang.Process <https://docs.oracle.com/javase/8/docs/api/java/lang/Process.html>`_ object.
        
            % takes a java.lang.Process (from runtime.exec())
            obj.proc = proc;
        end
        
        
        
        function delete(obj)
            % Destructor for a :class:`rc.aux_.ProcHandler` class. Also kills the associated process.
            
            obj.kill();
        end
        
        
        
        function wait_for(obj, timeout)
            % Wait for the process in :attr:`proc` to complete. Poll with a particular interval to allow MATLAB to run other processes.
            %
            % :param timeout: The poll interval in seconds.

            while obj.proc.isAlive()
                pause(timeout)
            end
            
            % make sure it's gone
            obj.kill();
        end
        
        
        
        function kill(obj)
            % Terminate the process in :attr:`proc`. Does not allow the process to run any kind of cleanup.

            obj.proc.destroy();
        end
    end
end
            