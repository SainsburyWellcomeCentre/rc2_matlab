classdef TCPIPcommunication_DoubleRotation < handle
    
    properties
        
        remote_ip
        remote_port_prepare
        remote_port_stimulus
        
        tcp_client = [];
        tcp_client_stimulus = [];
        
    end
    
    
    methods
        
        function obj = TCPIPcommunication_DoubleRotation(config)
            
            obj.remote_ip = config.connection.remote_ip;
            obj.remote_port_prepare = config.connection.remote_port_prepare;
            obj.remote_port_stimulus = config.connection.remote_port_stimulus;
            
        end
        
        function obj = setup(obj)
            
            % setup connection to remote host
            obj.tcp_client = tcpclient(obj.remote_ip, obj.remote_port_prepare);  % create a tcp client
            % setup another connection which handles the stimulus
            obj.tcp_client_stimulus = tcpclient(obj.remote_ip, obj.remote_port_stimulus);
            
        end

        function obj = delete(obj)
            
            delete(obj.tcp_client);
            delete(obj.tcp_client_stimulus);
            
        end
        
    end
end
