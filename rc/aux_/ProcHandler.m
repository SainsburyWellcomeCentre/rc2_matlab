classdef ProcHandler < handle
    
    properties
        proc
    end
    
    
    methods
        function obj = ProcHandler(proc)
            obj.proc = proc;
        end
        
        
        function delete(obj)
            obj.kill();
        end
        
        
        function wait_for(obj, timeout)
            % wait for the process in 'proc' to complete
            %   poll every 'timeout' seconds
            %       to allow MATLAB to run other things
            while obj.proc.isAlive()
                pause(timeout)
            end
            
            obj.kill();
        end
        
        
        function kill(obj)
            %   Although this terminates the process
            %       it does not allow the processe to run any kind of
            %       clean up
            obj.proc.destroy();
        end
    end
end
            