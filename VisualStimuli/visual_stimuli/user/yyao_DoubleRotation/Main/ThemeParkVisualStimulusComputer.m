classdef ThemeParkVisualStimulusComputer < handle
    
    properties
        config

        local_ip_address    % ip of visualsti PC
        local_port_prepare
        local_port_stimulus
        tcp_server
        tcp_server_stimulus

        ni
        
        is_running = false

        vis_protocol

        start_camera = true;
        
        camera_py
        save_dir
        git_dir

    end
    
    properties (SetAccess = private, Hidden = true)
        
        camera_proc
    end
    
    
    
    methods
        
        function obj = ThemeParkVisualStimulusComputer(config)% setup tcp/ip communication
            obj.config = config;
            obj.local_ip_address = config.connection.local_ip_address;
            obj.local_port_prepare = config.connection.local_port_prepare;
            obj.local_port_stimulus = config.connection.local_port_stimulus;
            obj.tcp_server = tcpserver(obj.local_ip_address, obj.local_port_prepare);
            obj.tcp_server_stimulus = tcpserver(obj.local_ip_address, obj.local_port_stimulus);

            % start experiment when receiving message from tcp client
            obj.tcp_server.configureCallback('terminator', @obj.start_experiment);

            % miniDAQ
            obj.ni.d = daq('ni');
            obj.ni.nidaq_dev = config.nidaq.dev; %= 'Dev2';
            obj.ni.di.channel_id = config.nidaq.di.channel_id; %= 'port0/line0';
            obj.ni.di.chan = addinput(obj.ni.d , obj.ni.nidaq_dev , obj.ni.di.channel_id , 'Digital');

            obj.camera_py = config.camera.camera_py;
            obj.save_dir = config.saving.save_dir;
        end
        
        
        function start_experiment(obj, ~, ~)
            
            %% setup
            fprintf('message received....\n')
            
            message = obj.tcp_server.readline();
            
            if obj.is_running
                fprintf('already running, sending signal to abort\n');
                obj.tcp_server.writeline('abort');
                return
            end
            
            message = strsplit(message, ':');
            
            protocol_name = [message{1} '_vis'];
            rec_name = message{2};
            
            % switch off the screen if vis_stim is disabled
            obj.vis_protocol = feval(protocol_name,obj.config);
            if obj.vis_protocol.enable
                system('C:\Users\Margrie_Lab1\Documents\tools\nircmd.exe monitor async_on');    % provides a blink on the screens if the screens are switched off (This command can switch on the screens but not input signal. The screens will return to NO INPUT logo mode.)
                pause(5);      % if the screens are off please switch them on manually while pausing
            else
                system('C:\Users\Margrie_Lab1\Documents\tools\nircmd.exe monitor async_off');
                pause(70);      % wait for the screens to switch off completely (make sure not to touch the mouse or keyboard to wake up the screens)
            end

            obj.is_running = true;
            
            % remove any data in the stimulus server
            flush(obj.tcp_server_stimulus);
            
            % start cameras
            if obj.start_camera
                fprintf('starting camera...\n');
                cmd = sprintf('python %s %s', obj.camera_py, rec_name);
                runtime = java.lang.Runtime.getRuntime();
                obj.camera_proc = runtime.exec(cmd);
             
                % camera script will try to create directory and fails if directory already exists, so wait here
                while ~isfolder(fullfile(obj.save_dir, rec_name))
                end
            else
                % create directory to save vis stim info and cameras
                if ~isfolder(fullfile(obj.save_dir, rec_name))
                    mkdir(fullfile(obj.save_dir, rec_name));
                end
            end

            vis_stim_save_fname = ...
                fullfile(obj.save_dir, rec_name, '_vis_sti_themepark.mat');
%             disp(vis_stim_save_fname)

%             str = [obj.ni.nidaq_dev , '_' , obj.ni.di.channel_id];
            fprintf('setup complete\n');
            obj.setup_complete();



            %% vis_stim
%             if obj.vis_protocol.enable      % vis_stim on
                try
                    fprintf('starting protocol...\n');
                    obj.vis_protocol.experiment.run(obj, vis_stim_save_fname);
                catch
                    fprintf('protocol error, sending signal to abort...\n\n');
                    obj.tcp_server.writeline('abort');
%                     obj.vis_protocol.experiment.abort();
                    fprintf('Abort!\n')
                end
%             else
%             end

            
        end
        
        
        
        function setup_complete(obj)
            
            if obj.tcp_server.Connected 
                obj.tcp_server.writeline('visual_stimulus_setup_complete');
            end
        end
        
        
        
        
        function [message, reply_status] = wait_for_rc2(obj)       % wait for message from RC2
            if obj.tcp_server_stimulus.Connected
                
                while obj.tcp_server_stimulus.NumBytesAvailable == 0
                    pause(0.001);
                end
                
                message = obj.tcp_server_stimulus.readline();
                reply_status = 1;

            else
                message = [];
                reply_status = -1;
                obj.tcp_server_stimulus.flush();
            end
        end
        
       
        
        function reset_tcp_servers(obj)
            
            delete(obj.tcp_server);
            delete(obj.tcp_server_stimulus);
            
            obj.tcp_server = tcpserver(obj.local_ip_address, obj.local_port_prepare);
            obj.tcp_server_stimulus = tcpserver(obj.local_ip_address, obj.local_port_stimulus);
            obj.tcp_server.configureCallback('terminator', @obj.start_experiment);
        end
        
        function delete(obj)
            delete(obj.tcp_server);
            delete(obj.tcp_server_stimulus);
        end
        
        function git_version = current_git_version(obj)
            [~, git_version] = system(sprintf('git --git-dir=%s rev-parse HEAD', obj.git_dir));
        end
    end
end
