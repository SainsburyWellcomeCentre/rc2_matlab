classdef RC2_DoubleRotation_GUIController < handle
    
    properties
        
        setup
        config
        view
        
        move_to_pos             % central stage move_to_pos
        move_to_pos_2           % outer stage move_to_pos
        stage_limits            % [stage远端范围, stage近端范围]
        speed_limits
        
        experiment_seq          % 记录实验过程参数
        current_script          % 当前加载的文件路径名
        
        protocol_gui
    end
    
    properties (SetAccess = private)
        
        preview_on
        sequence_on
    end
    
    
    
    methods
        
        function obj = RC2_DoubleRotation_GUIController(setup, config)   % 输入变量setup为RC2_DoubleRotation_Controller类函数，输入变量config为加载的config文件中的配置参数
            
            obj.setup = setup;      % RC2_DoubleRotation_Controller类函数
            obj.config = config;    % 加载的config文件中的配置参数
            obj.stage_limits = config.stage.max_limits;
            obj.speed_limits = config.ensemble.max_limits;
            obj.move_to_pos = config.stage.start_pos;
            
            obj.view = RC2_DoubleRotation_GUIView(obj);
        end
        
        
        function delete(obj)    
            delete(obj.view);
        end
        
      
        %% stage callback
        
        function changed_move_to_pos(obj)            % Central Stage面板Position文本输入框回调函数
            val = obj.view.handles.PositionEditField.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)   % 检查输入内容是否为数值
                
                msg = sprintf('"move to" position must be a number\n');  
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.PositionEditField.Value = sprintf('%.1f',obj.move_to_pos);
                return
            end
            
            
            if val > max(obj.stage_limits) || val < min(obj.stage_limits)  % 检查输入值是否在合法范围
                
                msg = sprintf('"move to" position must be between [%.2f, %.2f]\n', ...
                    min(obj.stage_limits), max(obj.stage_limits));
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                obj.view.handles.PositionEditField.Value = sprintf('%.1f',obj.move_to_pos);
                return
            end
            
            obj.move_to_pos = val;  % 将gui.view.handles.controller变量move_to_pos属性设置为输入值
        end
        
        function changed_move_to_pos_2(obj)            % Outer Stage面板Position文本输入框回调函数
            val = obj.view.handles.PositionEditField_2.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)   % 检查输入内容是否为数值
                
                msg = sprintf('"move to" position must be a number\n');  
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.PositionEditField_2.Value = sprintf('%.1f',obj.move_to_pos_2);
                return
            end
            
            
            if val > max(obj.stage_limits) || val < min(obj.stage_limits)  % 检查输入值是否在合法范围
                
                msg = sprintf('"move to" position must be between [%.2f, %.2f]\n', ...
                    min(obj.stage_limits), max(obj.stage_limits));
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_move_to_pos', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                obj.view.handles.PositionEditField_2.Value = sprintf('%.1f',obj.move_to_pos_2);
                return
            end
            
            obj.move_to_pos_2 = val;  % 将gui.view.handles.controller变量move_to_pos属性设置为输入值
        end

        function changed_speed(obj)             % Central Stage面板Speed文本输入框回调函数
            val = obj.view.handles.SpeedEditField.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)
                 
                msg = sprintf('speed must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
            
            
            if val < min(obj.speed_limits) || val > max(obj.speed_limits)
                
                msg = sprintf('speed must be between [%.2f, %.2f]\n', min(obj.speed_limits), max(obj.speed_limits));
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
        end

        function changed_speed_2(obj)           % Outer Stage面板Speed文本输入框回调函数
            val = obj.view.handles.SpeedEditField_2.Value;
            if ~isnumeric(val) || isinf(val) || isnan(val)
                 
                msg = sprintf('speed must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField_2.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
            
            
            if val < min(obj.speed_limits) || val > max(obj.speed_limits)
                
                msg = sprintf('speed must be between [%.2f, %.2f]\n', min(obj.speed_limits), max(obj.speed_limits));
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_speed', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.SpeedEditField_2.Value = sprintf('%.1f',obj.setup.ensemble.default_speed);
                return
            end
        end
        
        function move_to(obj)                   % Stage面板MOVE TO按钮的回调函数，将stage按指定速度移动到指定位置

            if all(isnan(obj.setup.ensemble.target_axes)), return, end
            
            pos = NaN([1,2]);
            speed = NaN([1,2]);
            if ismember(1,obj.setup.ensemble.target_axes)
                pos(1) = obj.view.handles.PositionEditField.Value;          % 传递输入的位置值（gui.view.handles.edit_move_to）
                speed(1) = obj.view.handles.SpeedEditField.Value;           % 传递输入的速度值（gui.view.handles.edit_speed）
                if ~isnumeric(pos(1)) || isinf(pos(1)) || isnan(pos(1))
                    error('position is not numeric')
                end
                if ~isnumeric(speed(1)) || isinf(speed(1)) || isnan(speed(1))
                    error('speed is not numeric')
                end
            end
            if ismember(0,obj.setup.ensemble.target_axes)
                pos(2) = obj.view.handles.PositionEditField_2.Value;
                speed(2) = obj.view.handles.SpeedEditField_2.Value;
                if ~isnumeric(pos(2)) || isinf(pos(2)) || isnan(pos(2))
                    error('position is not numeric')
                end
                if ~isnumeric(speed(2)) || isinf(speed(2)) || isnan(speed(2))
                    error('speed is not numeric')
                end
            end
            obj.setup.move_to(pos, speed);      % 调用Controller类move_to函数
        end
        
        
        function home_ensemble(obj)              % Stage面板HOME按钮的回调函数，将stage归为到近端
            obj.setup.home_ensemble();           % 调用Controller类home_ensemble函数
%             obj.view.show_ui_after_home();      % 启用GUI界面各项目
        end
        
        
        function reset_ensemble(obj)             % Stage面板RESET按钮的回调函数，将stage重置到固定位置，并重置参数到默认值。
            obj.setup.ensemble.reset();          % 调用Controller类ensemble属性变量（Ensemble类）reset函数
        end
        
        
        function stop_ensemble(obj)              % Stage面板STOP按钮的回调函数。终止Ensemble；杀进程；重置进程状态和参数。
            obj.setup.ensemble.abort();          % 调用Controller类ensemble属性变量（Ensemble类）abort函数
        end
        
        
        %% Experiment callback
        
        function set_script(obj)                % Experiment面板...按钮的回调函数
            
            start_dir = pwd;                    % pwd，确定当前文件夹
            [user_file, pathname] = uigetfile(fullfile(start_dir, '*.m'), 'Choose script to run...');
            if ~user_file; return; end
            
            obj.current_script = fullfile(pathname, user_file);
            obj.view.script_updated();
            [~, obj.setup.saver.index,~] = fileparts(obj.current_script);  % 更新saver类index属性变量 
            obj.view.index_updated();
        end
        
        
        function start_experiment(obj)                  % Experiment面板START EXPERIMENT按钮的回调函数
            
            if obj.preview_on
                msg = sprintf('stop preview before starting experiment\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % check that current script is selected
            if isempty(obj.current_script)
                
                msg = sprintf('no script selected\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % check that current script exists.
            if ~exist(obj.current_script, 'file')
                
                msg = sprintf('script selected doesn''t exist\n');
                
                 % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'start_experiment', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                
                return
            end
            
            % if experiment sequence is empty, we haven't started a
            % experiment sequence yet
            % else the we set is_running to the status of the training seq
            if isempty(obj.experiment_seq)
                is_running = false;
            else
                is_running = obj.experiment_seq.running;
            end
            
            % if training sequence hasn't been started, start it, else stop
            % it
            if is_running
                
                % stop the training sequence and reset the button
                obj.experiment_seq.stop();
                obj.view.handles.StartExperimentButton.Value = 0;
                obj.view.handles.StartExperimentButton.Text = 'Start Experiment';
            else
                
                
                % send animal, session, protocol name to remote host
                animal_id = obj.setup.saver.prefix;
                session = obj.setup.saver.suffix;
                protocol = obj.setup.saver.index;

                obj.setup.communication.setup();
                cmd = sprintf('%s:%s_%s_%s', protocol, animal_id, session, protocol);   % sprintf函数，将数据格式化为字符串或字符向量，按特定格式返回
                fprintf('sending protocol information to visual stimulus computer\n');
                obj.setup.communication.tcp_client.writeline(cmd);  % 调用tcpclient类的writeline方法，将后跟终止符的ASCII数据写入远程主机(remote host)
                
                % block until we get a response from remote host
                fprintf('waiting for visual stimulus computer to finish preparing\n');
                while obj.setup.communication.tcp_client.NumBytesAvailable == 0
                end
                return_message = obj.setup.communication.tcp_client.readline();   % 调用tcpclient类的readline方法，从远程主机(remote host)读取带终止符的ASCII字符串数据，赋值给变量return_message

                if strcmp(return_message, 'abort')   % strcmp(s1,s2) 比较 s1 和 s2，如果二者相同，则返回 1 (true)，否则返回 0 (false)。如果文本的大小和内容相同，则它们将视为相等。
                    error('return signal from visual stimulus computer was to abort'); % 假如从远程主机返回'abort'则终止。表明1)protocol在运行中；或2)未知的protocol
                elseif ~strcmp(return_message, 'visual_stimulus_setup_complete')
                    error('unknown return signal from visual stimulus computer');   % 假如从远程主机返回'visual_stimulus_setup_complete'则继续，否则报错
                end
                
                
                
                % 
                [~, fname] = fileparts(obj.current_script);
                obj.experiment_seq = feval(fname, obj.setup);  % 使用obj.setup作为传入参数执行fname指定的protocol函数，创建实验序列。返回值obj.experiment_seq为ProtocolSequence_DoubleRotation类变量。 feval函数，计算函数。
                % reinitialize the lick detection module....
                obj.setup.lick_detector = LickDetect(obj.setup, obj.config);   % 根据protocol重新配置lick_detector

                
                % start the Go/No-go gui... this seems to take a long time and is
                % non-blocking
                obj.protocol_gui = GoNogo_DoubleRotation_GUIController(obj.experiment_seq);  % 启动并配置trial绘图窗口，赋值给protocol_gui属性
                
                obj.view.handles.StartExperimentButton.Value = 1;
                obj.view.handles.StartExperimentButton.Text = 'Stop Experiment';
%                 addlistener(obj.experiment_seq, 'current_trial', 'PostSet', @(src, evnt)obj.experiment_trial_updated(src, evnt));
                
                obj.experiment_seq.run();   % 执行ProtocolSequence_DoubleRotation类run函数开始实验
                
                obj.experiment_seq = [];
                delete(obj.protocol_gui);
                obj.view.handles.StartExperimentButton.Value = 0;
                obj.view.handles.StartExperimentButton.Text = 'Start Experiment';
                
                
            end
        end
        
        %{
        function experiment_trial_updated(obj, ~, ~)                    % 更新RC2 GUI界面Experiment面板Trial#数文本显示
            str = sprintf('%i', obj.experiment_seq.current_trial);
            set(obj.view.handles.edit_experiment_trial, 'string', str);
        end
        %}
        
        %% Saving callback
        
        function set_save_to(obj)                   % Saving面板...按钮的回调函数。
            start_dir = obj.setup.saver.save_to;
            user_dir = uigetdir(start_dir, 'Choose save directory...');     % 获得选取的路径
            if ~user_dir; return; end
            
            obj.setup.set_save_save_to(user_dir);   % 将gui.setup.saver.save_to属性值修改为选取路径
            obj.view.save_to_updated();             % 
        end
        
        
        function set_file_path(obj)                 % Saving面板SavePathEditField文本输入框的回调函数
            str = obj.view.handles.SavePathEditField.Value;
            obj.setup.set_save_save_to(str);        % 将gui.setup.saver.save_to属性值修改为输入路径
            obj.view.save_to_updated();             % 
        end
        
        
        function set_file_prefix(obj)        % Saving面板AnimalID文本输入框的回调函数
%             str = get(h_obj, 'string');
            str = obj.view.handles.AnimalIDEditField.Value;
            obj.setup.set_save_prefix(str)          % 调用Control类set_save_prefix函数，gui.setup.saver.prefix属性值修改为输入的前缀文本
            obj.view.prefix_updated();
        end
        
        
        function set_file_suffix(obj)        % Saving面板Session文本输入框的回调函数
%             str = get(h_obj, 'string');
            str = obj.view.handles.SessionEditField.Value;
            obj.setup.set_save_suffix(str)          % 调用Control类set_save_suffix函数，gui.setup.saver.suffix属性值修改为输入的前缀文本
            obj.view.suffix_updated();
        end
        
        
        function enable_save(obj, h_obj)            % Saving面板Save复选框的回调函数
            val = get(h_obj, 'value');
            obj.setup.set_save_enable(val);
            obj.view.enable_updated();
        end
        
        
        %% Pump callback
        
        function give_reward(obj)                               % Pump面板REWARD按钮的回调函数
            obj.setup.give_reward()                             % 调用Controller类reward属性变量（Reward类）start_reward函数，启动计时器并回调give_reward函数，调用NI类do_pulse函数，Pump所在第1个DO通道('port0/line0')输出时长为dur的脉冲，其余通道保持原本状态。
        end
        
        
        function changed_reward_duration(obj)            % Pump面板Duration文本输入框的回调函数，修改给水单次奖励时长，单位为毫秒
            
            val = str2double(obj.view.handles.DurationEditField.Value);
            
            if ~isnumeric(val) || isinf(val) || isnan(val)
                msg = sprintf('reward duration must be a number\n');
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_reward_duration', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.DurationEditField.Value = sprintf('%.1f',obj.setup.reward.duration);
                return
            end
            
            status = obj.setup.reward.set_duration(val);        % 调用Controller类reward属性变量（Reward类）set_duration函数，将gui.setup.reward.duration值修改为输入的值
            if status == -1
                
                msg = sprintf('reward duration must be between %.1f and %.1f\n', ...
                    obj.setup.reward.min_duration, obj.setup.reward.max_duration);
                
                % print a message to the command window
                fprintf('%s: %s: %s', class(obj), 'changed_reward_duration', msg);
                
                % also print the message to the GUI
                obj.print_error(msg);
                obj.view.handles.DurationEditField.Value = sprintf('%.1f',obj.setup.reward.duration);      % 更新RC2 GUI界面显示
                return
            end
        end
        
        
        function pump_on(obj)                       % Pump面板ON按钮的回调函数，
        %%PUMP_ON(obj)
        %  Turn the pump on. To start filling a chamber for example.
            % 按钮被按下时，obj.view.handles.PumpONButton.Value值为1; 
            if obj.setup.pump.state
                obj.setup.pump_off();                           % 调用NI类do_toggle函数切换名为'pump'的DO通道(port0/line0)状态向泵输出脉冲，持续给水奖励。
                obj.view.handles.PumpONButton.Text = 'ON';
            else
                obj.setup.pump_on();                            % 调用NI类do_toggle函数切换名为'pump'的DO通道(port0/line0)状态停止脉冲输出，中断奖励。
                obj.view.handles.PumpONButton.Text = 'OFF';     % 将按钮文本更改为OFF
            end
        end
        
        %% Sound callback
        
        function toggle_sound(obj)                  % Sound面板PLAY按钮回调函数，播放状态切换
            if ~obj.setup.sound.enabled
                return
            end
            if obj.setup.sound.state                % 假如正在播放中则终止当前播放，更新按钮文本显示为'PLAY'
                obj.setup.stop_sound();
                obj.view.handles.PlaySoundButton.Text = 'PLAY';
            else                                    % 假如未在播放中则启动播放，更新按钮文本显示为'STOP'
                obj.setup.play_sound();              
                obj.view.handles.PlaySoundButton.Text = 'STOP';
            end
        end
        
        
        function enable_sound(obj)                          % Sound面板Enable单选框回调函数
            obj.setup.sound.enable();
            obj.view.handles.PlaySoundButton.Enable = 'on';
        end
        
        
        function disable_sound(obj)                         % Sound面板Disable单选框回调函数
            obj.setup.sound.disable();
            obj.view.handles.PlaySoundButton.Enable = 'off';
        end
        
        %% AI Preview callback
        function toggle_acquisition(obj)                % AI Preview面板PREVIEW按钮回调函数，启动/停止预览实时绘图窗口
            % if a acquisition with data-saving is running don't do
            % anything.
            if obj.setup.acquiring; return; end         % 如果正在采集数据则返回
            
            if obj.setup.acquiring_preview              % 如果正在预览则停止预览，按钮文本更新为'PREVIEW'，preview_on属性更新为false
                obj.setup.stop_preview()
                obj.view.handles.PreviewButton.Text = 'PREVIEW';
                obj.preview_on = false;
            else                                        % 如果未在预览则启动预览，按钮文本更新为'STOP'，preview_on属性更新为true
                obj.setup.start_preview()
                obj.view.handles.PreviewButton.Text = 'STOP';
                obj.preview_on = true;
            end
        end

        
        %%
        function print_error(obj, msg)
            obj.view.handles.messageLable.Text = sprintf('Error: %s', msg);
            obj.view.handles.messageButton.Visible = 'on';
        end
        
        
        function acknowledge_error(obj)
            obj.view.handles.messageLable.Text = '';
            obj.view.handles.messageButton.Visible = 'off';
        end
        
    end
end