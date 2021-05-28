classdef ThemeParkRC2 < handle
    
    properties
        
        remote_ip = '172.24.242.181';
        remote_port_prepare = 43056;
        remote_port_stimulus = 43057;
        
        ctl
        gui
        
        protocol
        protocol_gui
    end
    
    
    
    methods
        
        function obj = ThemeParkRC2()
            
            config = config_sweiler();
            obj.ctl = RC2Controller(config);
            obj.gui = rc2guiController(obj.ctl, config);
        end
        
        
        
        function start_protocol(obj, protocol_id)
            
            % make sure protocol is known
            assert(ismember(protocol_id, 1:5), 'Unknown protocol ID (1-5)');
            
            % ask for animal ID and session name
            animal_id = input('Animal ID: ', 's');
            session_name = input('Session name: ', 's');
            
            % setup connection to remote computer
            tcp_client = tcpclient(obj.remote_ip, obj.remote_port_prepare);
            % setup another connection which handles the stimulus
            tcp_client_stimulus = tcpclient(obj.remote_ip, obj.remote_port_stimulus);
            
            % send protocol, animal and session name
            cmd = sprintf('protocol%i:%s_%s', protocol_id, animal_id, session_name);
            tcp_client.writeline(cmd);
            
            % block until we get a response
            fprintf('Waiting for response from visual stimulus computer:\n');
            while tcp_client.NumBytesAvailable == 0
            end
            return_message = tcp_client.readline();
            
            
            if strcmp(return_message, 'abort')
                error('Return signal from visual stimulus computer was to abort');
            elseif ~strcmp(return_message, 'visual_stimulus_setup_complete')
                error('Unknown return signal from visual stimulus computer');
            end
            
            % set the save name
            obj.ctl.saver.prefix = animal_id;
            obj.ctl.saver.suffix = session_name;
            
            % setup the protocol.. which differ by licking behaviour
            config.lick_detect.enable           = true;
%             config.lick_detect.trigger_channel = 1;
%             config.lick_detect.lick_channel = 2;
            if protocol_id == 1
                config.lick_detect.n_windows        = 1;
                config.lick_detect.window_size_ms   = 8000;
                config.lick_detect.n_lick_windows   = 1;
                config.lick_detect.detection_window_is_triggered = false;
            elseif protocol_id == 2
                config.lick_detect.n_windows        = 8;
                config.lick_detect.window_size_ms   = 250;
                config.lick_detect.n_lick_windows   = 1;
                config.lick_detect.detection_window_is_triggered = true;
            elseif protocol_id == 3
                config.lick_detect.n_windows        = 8;
                config.lick_detect.window_size_ms   = 250;
                config.lick_detect.n_lick_windows   = 2;
                config.lick_detect.detection_window_is_triggered = true;
            elseif protocol_id == 4
                config.lick_detect.n_windows        = 8;
                config.lick_detect.window_size_ms   = 250;
                config.lick_detect.n_lick_windows   = 2;
                config.lick_detect.detection_window_is_triggered = true;
            elseif protocol_id == 5
                config.lick_detect.n_windows        = 8;
                config.lick_detect.window_size_ms   = 250;
                config.lick_detect.n_lick_windows   = 2;
                config.lick_detect.detection_window_is_triggered = true;
            end
            
            % reinitialize the lick detection module....
            obj.ctl.lick_detector = LickDetect(obj.ctl, config);
            
            % create the protocol
            obj.protocol = ThemeParkProtocol(obj.ctl, tcp_client_stimulus, protocol_id);
            
            % start the gui... this seems to take a long time and is
            % non-blocking
            if ismember(protocol_id, 2:5)
                obj.protocol_gui = ProtocolGUIController(obj.protocol);
            end
            
            % run the protocol
            obj.protocol.run();
            
            % close the gui
            if ismember(protocol_id, 2:5)
                delete(obj.protocol_gui);
            end
        end
    end
end
