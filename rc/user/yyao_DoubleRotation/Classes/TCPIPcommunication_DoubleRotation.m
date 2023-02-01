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
            obj.tcp_client = tcpclient(obj.remote_ip, obj.remote_port_prepare);  % 返回值为tcpclient类变量。t = tcpclient(address,port) 创建一个TCP/IP客户端，该客户端连接到与远程主机address和远程端口port相关联的服务器。address的值可以是远程主机名或远程主机IP地址。port的值必须是1到65535之间的一个数字。输入address设置Address属性，输入port设置Port属性。
            % setup another connection which handles the stimulus
            obj.tcp_client_stimulus = tcpclient(obj.remote_ip, obj.remote_port_stimulus);
            
        end

        function obj = delete(obj)
            
            delete(obj.tcp_client);
            delete(obj.tcp_client_stimulus);
            
        end
        
    end
end
