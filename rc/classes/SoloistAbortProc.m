classdef SoloistAbortProc < handle
    
    properties (SetAccess = private)
        
        cmd
        proc
        writer
        reader
    end
    
    
    methods
        
        function obj = SoloistAbortProc(cmd)
        %%obj = SOLOISTABORTPROC(cmd)
        %  Class for controlling a separate process which itself controls
        %  the abortion and resetting of motion on the soloist.
        
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
        %%DELETE(obj)
        %   Des
            % upon deletion.
            obj.close()
        end
        
        
        function run(obj, sig)
            % send the abort signal.
            %  this doesn't close the process
            VariableDefault('sig', 'stop');
            obj.send_signal(sig);
        end
        
        
        function close(obj)
            % send close signal to gracefully disconnect
            % also destroy the process if it still exists.
            obj.send_signal('close');
            obj.proc.destroy();
        end
        
        
        
        function send_signal(obj, sig)
            
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