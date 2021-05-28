classdef ThemeParkVisualStimulusComputer < handle
    
    properties
        
        local_ip_address = '172.24.242.181'
        local_port_prepare = 43056
        local_port_stimulus = 43057
        
        tcp_server
        tcp_server_stimulus
        
        is_running = false
        
        start_camera = false;
        camera_exe
    end
    
    properties (SetAccess = private, Hidden = true)
        
        camera_proc
    end
    
    
    
    methods
        
        function obj = ThemeParkVisualStimulusComputer()
            
%             obj.camera_exe = config.camera_exe;
            
            obj.tcp_server = tcpserver(obj.local_ip_address, obj.local_port_prepare);
            obj.tcp_server_stimulus = tcpserver(obj.local_ip_address, obj.local_port_stimulus);
            
            obj.tcp_server.configureCallback('terminator', @obj.message_received);
        end
        
        
        function message_received(obj, ~, ~)
            
            message = obj.tcp_server.readline();
            
            if obj.is_running
                fprintf('already running, sending signal to abort\n');
                obj.tcp_server.writeline('abort');
                return
            end
            
            message = strsplit(message, ':');
            
            protocol_id = message{1};
            rec_name = message{2};
            
            obj.is_running = true;
            
            % start cameras
            if obj.start_camera
                cmd = sprintf('python %s %s', obj.camera_exe, rec_name);
                runtime = java.lang.Runtime.getRuntime();
                obj.camera_proc = runtime.exec(cmd);
            end


            switch protocol_id
                case 'protocol1'
                    example_vis_stim_function(obj);
                case 'protocol2'
                    example_vis_stim_function(obj);
                case 'protocol3'
                    example_vis_stim_function(obj);
                case 'protocol4'
                    example_vis_stim_function(obj);
                case 'protocol5'
                    example_vis_stim_function(obj);
                otherwise
                    fprintf('unknown protocol, sending signal to abort\n');
                    obj.tcp_server.writeline('abort');
            end
            
            % protocol finished
            obj.is_running = false;
        end
        
        
        
        function setup_complete(obj)
            obj.tcp_server.writeline('visual_stimulus_setup_complete');
        end
        
        
        
        
        function reply = wait_for_rc2(obj)
            while obj.tcp_server_stimulus.NumBytesAvailable == 0
                pause(0.001);
            end
            reply = obj.tcp_server_stimulus.readline();
        end
        
        
        
        function notify_of_stimulus_type(obj, is_s_plus)
            if is_s_plus
                obj.tcp_server_stimulus.writeline('s_plus');
            else
                obj.tcp_server_stimulus.writeline('s_minus');
            end
        end
        
        
        
        function reset_tcp_servers(obj)
            
            delete(obj.tcp_server);
            delete(obj.tcp_server_stimulus);
            
            obj.tcp_server = tcpserver(obj.local_ip_address, obj.local_port_prepare);
            obj.tcp_server_stimulus = tcpserver(obj.local_ip_address, obj.local_port_stimulus);
            obj.tcp_server.configureCallback('terminator', @obj.message_received);
        end
    end
end
