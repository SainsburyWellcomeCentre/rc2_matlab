classdef SoloistAbortProc < handle
    
    properties
        cmd
        proc
        writer
        reader
    end
    
    methods
        function obj = SoloistAbortProc(cmd)
            
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
            % upon deletion.
            obj.close()
        end
        
        
        function run(obj)
            % send the abort signal.
            %  this doesn't close the process
            obj.send_signal('abort');
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
                fprintf('abort process is not alive.\n');
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
            
            % re-open up the abort.exe process... i.e. connect to soloist and
            % wait for input on standard input.
            runtime = java.lang.Runtime.getRuntime();
            obj.proc = runtime.exec(obj.cmd);
            
            % open up pipes to the process
            obj.writer = obj.proc.getOutputStream();
            obj.reader = obj.proc.getInputStream();
        end
        
    end
end