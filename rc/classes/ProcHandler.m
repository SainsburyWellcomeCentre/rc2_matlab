classdef ProcHandler < handle
% ProcHandler Class for loose wrapper around a MATLAB java.lang.Process object
%
%   ProcHandler Properties:
%       proc           - the java.lang.Process object
%
%   ProcHandler Methods:
%       delete         - destructor
%       wait_for       - blocks and waits for process to finish
%       kill           - kills the process

    properties (SetAccess = private)
        
        proc
    end
    
    
    
    methods
        
        function obj = ProcHandler(proc)
        %obj = PROCHANDLER(proc)
        %   Class providing loose wrapper around a MATLAB java.lang.Process
        %   object... upon deletion it kills the process (would probably do
        %   that anyway)
        %   
        %   Also provides a 'wait_for' method which waits for the process
        %   to end, but runs a pause so that other MATLAB processing can
        %   occur (the native .waitFor blocks)
        %
        %   Along with ProcArray, want to find a better solution.
        
            % takes a java.lang.Process (from runtime.exec())
            obj.proc = proc;
        end
        
        
        
        function delete(obj)
        %%delete Destructor
        
            obj.kill();
        end
        
        
        
        function wait_for(obj, timeout)
        %%WAIT_FOR(obj, timeout)
            % wait for the process in 'proc' to complete
            %   poll every 'timeout' seconds
            %       to allow MATLAB to run other things
            
            while obj.proc.isAlive()
                pause(timeout)
            end
            
            % make sure it's gone
            obj.kill();
        end
        
        
        
        function kill(obj)
            %   Although this terminates the process
            %       it does not allow the process to run any kind of
            %       clean up on Windows
            
            obj.proc.destroy();
        end
    end
end
            