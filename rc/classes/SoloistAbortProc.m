classdef SoloistAbortProc < handle
% SoloistAbortProc Class for controlling a separate process which itself
% controls the aborting and resetting of motion on the soloist.
%
%   SoloistAbortProc Properties:
%       cmd         - full filename of the abort.exe executable
%       proc        - handle to the java.lang.Runtime.exec process object
%       writer      - stream to the standard output of the process
%       reader      - stream to the standard input of the process
%
%   SoloistAbortProc Methods:
%       delete      - destructor
%       run         - run a signal
%       close       - close the process
%       send_signal - send the signal
%       restart     - restart the process

    properties (SetAccess = private)
        
        cmd
        proc
        writer
        reader
    end
    
    
    
    methods
        
        function obj = SoloistAbortProc(cmd)
        % SoloistAbortProc
        %
        %   SoloistAbortProc(COMMAND) creates object of this class for
        %   controlling a separate process which itself controls 
        %   the aborting and resetting of motion on the soloist. COMMAND is
        %   the full filename of the abort.exe executable.
        %
        %   See also README in Soloist directory and `abort.c` file.
        
            % open up the abort.exe process... i.e. connect to soloist and
            % wait for input on standard input.
            obj.cmd = cmd;
            runtime = java.lang.Runtime.getRuntime();
            obj.proc = runtime.exec(obj.cmd);
            
            % open up pipes to the process
            obj.writer = obj.proc.getOutputStream();
            obj.reader = obj.proc.getInputStream();
        end
        
        
        
        function delete(obj)
        %%delte Destructor
        
            % upon deletion.
            obj.close()
        end
        
        
        
        function run(obj, sig)
        %%run Runs one of the functions in abort.exe process
        %
        %   run(SIGNAL) sends the signal in string SIGNAL. SIGNAL can be
        %   'abort', 'stop', 'reset_pso' or 'close'.
        %
        %   See also README in Soloist directory and `abort.c` file.
        
            % send the abort signal.
            %  this doesn't close the process
            VariableDefault('sig', 'stop');
            obj.send_signal(sig);
        end
        
        
        
        function close(obj)
        %%close Close the abort.exe process
        %
        %   close() send 'close' signal to gracefully disconnect also
        %   destroy the process if it still exists. 
        
            obj.send_signal('close');
            obj.proc.destroy();
        end
        
        
        
        function send_signal(obj, sig)
        %%send_signal Sends a signal to the abort.exe process
        %
        %   send_signal(SIGNAL) sends the signal in string SIGNAL. SIGNAL
        %   can be  'abort', 'stop', 'reset_pso' or 'close'.
        %
        %   See also README in Soloist directory and `abort.c` file.
        
            % determine if process is still alive.
            if ~obj.proc.isAlive()
                fprintf('abort process is not alive...restarting\n');
                obj.restart();
                return
            end
            
            obj.writer.write(double(sprintf('%s\n', sig)));
            obj.writer.flush()
            
            t = tic;
            while obj.reader.available() == 0
                if toc(t) > 5
                    fprintf('no return signal, %s, from abort.exe\n', sig);
                    return
                end
            end
            
            d = [];
            for i = 1 : obj.reader.available()
                d(i) = obj.reader.read();
            end
            
            str = char(d);
            fprintf('return message: %s\n', str);
        end
        
        
        
        function restart(obj)
        %%restart Restarts the abort.exe process
        %
        %   restart() restarts the process. Does nothing if it is already
        %   alive.
        
            if obj.proc.isAlive()
                fprintf('abort.exe is already running.\n')
                return
            end
            
            % confirm that the restart is taking place
            fprintf('restarting abort.exe...')
            
            % re-open up the abort.exe process... i.e. connect to soloist and
            % wait for input on standard input.
            runtime = java.lang.Runtime.getRuntime();
            obj.proc = runtime.exec(obj.cmd);
            
            % open up pipes to the process
            obj.writer = obj.proc.getOutputStream();
            obj.reader = obj.proc.getInputStream();
            
            if obj.proc.isAlive()
                fprintf('restarted.\n')
            else
                fprintf('could not restart?\n')
            end
        end
    end
end
