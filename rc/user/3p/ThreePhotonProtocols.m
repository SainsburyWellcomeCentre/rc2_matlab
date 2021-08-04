classdef ThreePhotonProtocols < handle
    
    properties
        
        save_to = 'D:\Data\3PData';
        
        remote_ip = '127.0.0.1';
        remote_port = 43056;
        
        config
        ctl
        
        valid_protocols = 1:5
    end
    
    
    
    methods
        
        function obj = ThreePhotonProtocols()
            
            obj.config = config_default_3P(false);
            obj.ctl = Controller(obj.config);
        end
        
        
        
        function delete(obj)
            
            delete(obj.ctl);
        end
        
        
        
        function start_protocol(obj, protocol_id)
            
            % make sure protocol is known
            assert(ismember(protocol_id, obj.valid_protocols), 'Unknown protocol ID');
            
            % setup connection to remote matlab session
            tcp_client = tcpclient(obj.remote_ip, obj.remote_port);
            
            % ask for animal ID and session name
            animal_id = input('Animal ID: ', 's');
            session_name = input('Date and exp name: ', 's');
            
            % set the save name
            obj.ctl.saver.set_prefix(animal_id);
            obj.ctl.saver.set_suffix(session_name);
            
            % send protocol, animal and session name
            cmd = sprintf('protocol%i:::%s:::%s:::%s:::%03i', protocol_id, obj.config.saving.save_to, animal_id, session_name, obj.ctl.saver.index);
            tcp_client.writeline(cmd);
            
            % block until we get a response
            fprintf('Waiting for response from visual stimulus computer:\n');
            while tcp_client.NumBytesAvailable == 0
            end
            return_message = tcp_client.readline();
            
            
            if ~strcmp(return_message, 'visual_stimulus_ready')
                error('Return signal from visual stimulus computer was to abort');
            end
            
            % run the protocol
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
        end
        
        
        
        function stop(obj)
            
            obj.ctl.stop_acq();
        end
    end
end
