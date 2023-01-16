classdef SoloistAbortProc < handle
    % SoloistAbortProc class for controlling a separate process which itself
    % controls the aborting and resetting of motion on the soloist.

    properties (SetAccess = private)
        cmd % Full filename of the abort.exe executable.
        proc % Handle to the java.lang.Runtime.exec process object.
        writer % Stream to the standard output of the process.
        reader % Stream to the standard input of the process.
    end
    
    
    
    methods
        function obj = SoloistAbortProc(cmd)
            % Constructor for a :class:`rc.dev.SoloistAbortProc` device.
            % Controls a separate process which itself controls the aborting and resetting of motion on the soloist.
            %
            % :param cmd: The full filename of the abort.exe executable.
        
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
            % Destructor for :class:`rc.dev.SoloistAbortProc` device.
        
            % upon deletion.
            obj.close()
        end
        
        
        function run(obj, sig)
            % Runs one of the functions in the abort.exe process.
            %
            % :param sig: String specifying the function signal: 'abort', 'stop', 'reset_pso', 'close'.
        
            % send the abort signal.
            %  this doesn't close the process
            VariableDefault('sig', 'stop');
            obj.send_signal(sig);
        end
        
        
        function close(obj)
            % Close the abort.exe process. Send the 'close' signal to gracefully disconnect and also destroy the process if it still exists.
        
            obj.send_signal('close');
            obj.proc.destroy();
        end
        
        
        function send_signal(obj, sig)
            % Sends a signal to the abort.exe process.
            %
            % :param sig: String specifying the function signal: 'abort', 'stop', 'reset_pso', 'close'.
        
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
            % Restarts the abort.exe process. Does nothing if the process is already alive.
        
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
