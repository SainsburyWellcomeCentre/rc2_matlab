classdef ProtocolSequence_DoubleRotation < handle
    
    properties
        ctl
        sequence = {}
        running = false;
        abort = false;
        current_sequence
        
        stimulus_type_list = {}
        is_correct = []
        h_listener_reward
        
    end
    
    properties (SetObservable = true)
        current_trial = 0;
        n_correct_s_plus_trials = 0
        n_incorrect_s_plus_trials = 0
        n_correct_s_minus_trials = 0
        n_incorrect_s_minus_trials = 0
        n_rewards_given = 0;
    end
    
    properties (Hidden = true)
        gui_view
    end
    
    methods
        function obj = ProtocolSequence_DoubleRotation(ctl,view)
            obj.ctl = ctl;  % ctl为RC2_DoubleRotation_Controller类函数
            obj.h_listener_reward = addlistener(obj.ctl.reward, 'n_rewards_counter', 'PostSet', @obj.n_rewards_given_updated); 
            % 为某个预定义的属性事件创建侦听程序。当侦听到源对象obj.setup.reward的n_rewards_counter属性变化时，则在属性设置之后立即触发（'PostSet'）回调函数n_rewards_given_updated，函数功能为给予奖励。
            obj.gui_view = view;
        end
        
        function add(obj, protocol)
            obj.sequence{end+1} = protocol;
        end
        
        function delete(obj)
            delete(obj.h_listener_reward);
        end
        
        function run(obj,enable_vis_stim)
            
            obj.prepare();
            
            h = onCleanup(@obj.cleanup);  % 函数完成后的清理任务。在函数@obj.cleanup终止时隐式清除所有局部变量，无论是正常完成还是强制退出，如出现错误或按 Ctrl+C。
            
            obj.ctl.reward.reset_n_rewards_counter();   % n_rewards_counter重置为0，total_duration_on重置为0
            
            obj.ctl.play_sound(); 
            obj.ctl.ensemble.online = [true true];
%             obj.ctl.ensemble.communicate(); % startup initial communication
%             obj.ctl.ensemble.target_axes = obj.ctl.ensemble.all_axes;   % [0,1]
%             obj.ctl.ensemble.move_to([5 5], [40 40], false);
            obj.ctl.ensemble.target_axes = obj.ctl.ensemble.all_axes;   % [0,1]
            obj.ctl.ensemble.home();        % home both motors
            obj.ctl.prepare_acq();   % 实验开始前的准备：保存NIDAQ采样配置信息(.cfg)；侦听NIDAQ数据采集'数据可用'事件；重置实时绘图窗口变量；初始化舔检测器
            obj.ctl.start_acq();     % 开启计时器(CO to camara)和AI 
            obj.running = true;
            
            if enable_vis_stim
                fprintf('prepare to start\n');
                    while obj.ctl.communication.tcp_client.NumBytesAvailable == 0
                    end
                return_message = obj.ctl.communication.tcp_client.readline();
           
                if ~strcmp(return_message, 'ready')
                    fprintf('preperation failed\n')
                    obj.stop(); % abort and reset
                end
            end

            for i = 1 : length(obj.sequence)    % trial start
                
                %% preperation
                obj.current_sequence = obj.sequence{i};
                obj.current_trial = i;
                
                % setup current trial motor motion
%                 target_axes = [NaN,1];  % outer
%                 target_axes = [0,NaN];  % central
                if obj.sequence{i}.stage.enable_motion
                    target_axes = obj.ctl.ensemble.all_axes;  % [0,1]
                    if ~obj.sequence{i}.stage.central.enable
                        target_axes(1) = NaN;
                    end
                    if ~obj.sequence{i}.stage.outer.enable
                        target_axes(2) = NaN;
                    end
                    w = double(read_bin('C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\rc\user\mvelez(not in use)\waveforms\CA_529_2_trn11_001_single_trial_004.bin',1));
                    waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;
                    obj.ctl.load_velocity_waveform(waveform);   % load the velocity waveform to NIDAQ
                    obj.ctl.ensemble.target_axes = obj.ctl.ensemble.all_axes;   % [0,1]
                    obj.ctl.ensemble.reset_pso();   % Reset PSO
                    obj.ctl.ensemble.target_axes = target_axes;
                    ensembleHandle = obj.ctl.ensemble.listen();      % Set the ensemble to listen

%                     obj.ctl.communication.tcp_client_stimulus.writeline('motion_prepared');   % 向远程主机发送带终止符的信息'motion_prepared'
                else
%                     obj.ctl.communication.tcp_client_stimulus.writeline('motion_disabled');   % 向远程主机发送带终止符的信息'motion_disabled'
                end
%                 waveform_central = voltagewaveform_generator(obj.sequence{i}.stage, 10000);
%                 if obj.sequence{i}.stage.central.distance < 0 
%                     waveform_central = -waveform_central;
%                 end
%                 waveform_outer = voltagewaveform_generator(obj.sequence{i}.stage, 10000);
%                 if obj.sequence{i}.stage.central.distance < 0 
%                     waveform_outer = -waveform_outer;
%                 end
%                 waveform = zeros(length(waveform_outer),2);
%                 waveform(:,1) = waveform_outer;
%                 waveform(:,2) = waveform_central;
                
                % setup current trial visual stimuli
                if obj.sequence{i}.vis.enable_vis_stim
                    fprintf('start_vis_stim_preparation\n'); 

                    % send current trial visual stimuli information to remote host
                    cmd = sprintf('%i', obj.sequence{i}.vis.vis_stim_lable);   % sprintf函数，将数据格式化为字符串或字符向量，按特定格式返回
                    fprintf('sending current trial to visual stimulus computer\n');
                    obj.ctl.communication.tcp_client_stimulus.writeline(cmd);  % 调用tcpclient类的writeline方法，将后跟终止符的ASCII数据写入远程主机(remote host)
                    
                    fprintf('waiting for visual stimulus computer\n');
                    while obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                    end
                    return_message = obj.ctl.communication.tcp_client_stimulus.readline(); 
    
                    if ~strcmp(return_message, 'received')
                        fprintf('trial type message failed\n')
                        obj.stop();
                    end
                else
                    obj.ctl.communication.tcp_client_stimulus.writeline('vis_stim_disabled');   % 向远程主机发送带终止符的信息'vis_stim_disabled'
                end
                
                % setup current trial lick detector
                obj.ctl.lick_detector.enable_reward = obj.sequence{i}.trial.enable_reward;
                obj.ctl.lick_detector.start_trial();    % reset the lick detector
                
                % store stimulus type
%                 fprintf('trial finished, updating response variables...');
                obj.stimulus_type_list{obj.current_trial} = obj.sequence{i}.trial.stimulus_type;   % 存储当前trial刺激类型信息到列表
                
                fprintf('preperation done\n');
                
                %% Start trial
                
                % send signal back to visual stimulus computer
                % assumes that vis stim computer is waiting...
                fprintf('Trial %i: sending start message to vis stim computer\n',i);
                obj.ctl.communication.tcp_client_stimulus.writeline('start_trial');   % 向远程主机发送带终止符的信息'start_trial'
                
                if obj.sequence{i}.stage.enable_motion
                    % moving the stages
                    % TODO: lick_detect.trigger

                    obj.ctl.play_velocity_waveform();   % Start playing the waveform on the NIDAQ
                    while obj.ctl.ni.ao.task.IsRunning  % check to see AO is still running
    %                     disp('>>> AO task running');
                        pause(0.005);
                        if obj.abort
                            obj.running = false;
                            obj.abort = false;
                            return
                        end
                    end
                    obj.ctl.ensemble.target_axes = target_axes;
                    obj.ctl.ensemble.stop_listen(ensembleHandle);      % Stop Ensemble listen

                    
                    obj.ctl.communication.tcp_client_stimulus.writeline('motion_end');   % 向远程主机发送带终止符的信息'motion_end'
                    
                end
                
                if obj.sequence{i}.vis.enable_vis_stim
                    % wait for vis_stim to end
                    abort_trial = obj.wait_for_trial_end();   % 接收来自远程主机的视觉刺激结束信息。如果信息为'trial_end'则继续运行protocol，否则终止。
                    if abort_trial; return; end
                end
                
                %% trial end
                % if the protocol is S+, then lick is correct response
                if strcmp(obj.sequence{i}.trial.stimulus_type, 's_plusL')||strcmp(obj.sequence{i}.trial.stimulus_type, 's_plusR')

                    if obj.ctl.lick_detector.lick_detected   % 对于S+ trial，如果lick_detected值为true（检测到有效的舔食行为）
                        % correct S+ trial
                        obj.is_correct(obj.current_trial) = true;  % 根据is_correct属性值为true
                        obj.n_correct_s_plus_trials = obj.n_correct_s_plus_trials + 1;
                    else
                        % incorrect S+ trial
                        obj.is_correct(obj.current_trial) = false;
                        obj.n_incorrect_s_plus_trials = obj.n_incorrect_s_plus_trials + 1;
                    end

                elseif strcmp(obj.sequence{i}.trial.stimulus_type, 's_minusL')||strcmp(obj.sequence{i}.trial.stimulus_type, 's_minusR')

                    if obj.ctl.lick_detector.lick_detected
                        % incorrect S- trial
                        obj.is_correct(obj.current_trial) = false;
                        obj.n_incorrect_s_minus_trials = obj.n_incorrect_s_minus_trials + 1;
                    else
                        % correct S- trial
                        obj.is_correct(obj.current_trial) = true;
                        obj.n_correct_s_minus_trials = obj.n_correct_s_minus_trials + 1;
                    end
                end
                
                pause(5.0);     % wait for 5 seconds

                % reset stages
                obj.ctl.ensemble.target_axes = obj.ctl.ensemble.all_axes;   % [0,1]
                obj.ctl.ensemble.home();        % reset both motors to Homed position

%                 fprintf('done\n');
                
                %{
                % start running this protocol
                finished_forward = obj.sequence{i}.run();
                
                if finished_forward
                    obj.forward_trials = obj.forward_trials + 1;
                else
                    obj.backward_trials = obj.backward_trials + 1;
                end
                %}
                
            end     % trial end
            fprintf('Protocol finished\n');
            % let cleanup handle the stopping
        end
        
        
        function prepare(obj)
            
            obj.current_trial = 0;
            obj.n_correct_s_plus_trials = 0;
            obj.n_incorrect_s_plus_trials = 0;
            obj.n_correct_s_minus_trials = 0;
            obj.n_incorrect_s_minus_trials = 0;
            obj.n_rewards_given = 0;
            
        end
        
        
        function stop(obj)
            
            if isempty(obj.current_sequence)
                return
            end
            obj.abort = true;
%             obj.current_sequence.stop();
            %delete(obj.current_sequence);
            obj.current_sequence = [];
        end
        
        
        function abort_trial = wait_for_trial_end(obj)
            
            if obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                fprintf('waiting for end of trial message\n');
            end
            
            abort_trial = false;
            while obj.ctl.communication.tcp_client_stimulus.NumBytesAvailable == 0
                pause(0.001);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    abort_trial = true;
                    return
                end
            end
            
            fprintf('reading end of trial message');
            msg = obj.ctl.communication.tcp_client_stimulus.readline();    % 从远程主机(remote host)读取带终止符的信息。正常信息为'trial_end'
            fprintf('%s\n', msg);
            assert(strcmp(msg, 'trial_end'));   % 假如信息不是'trial_end'则报错。assert函数，违反条件时生成错误。
        end

        function n_rewards_given_updated(obj, ~, ~)
            
            obj.n_rewards_given = obj.ctl.reward.n_rewards_counter;   % 对给予奖励进行计数
        end

        
        function cleanup(obj)
            
            fprintf('running cleanup in protseq\n')
            obj.running = false;
            obj.ctl.ensemble.stop();
            obj.ctl.ensemble.online = [false false];
            obj.ctl.communication.tcp_client_stimulus.writeline('rc2_stopping');
            obj.ctl.communication.delete();
            obj.gui_view.handles.StartExperimentButton.Value = 0;
            obj.gui_view.handles.StartExperimentButton.Text = 'Start Experiment';

            % log the info
            fname = [obj.ctl.saver.save_root_name(), '_themepark.mat'];   % 文件保存名，'yyyymmddHHMM_SS_001_themepark.mat' % SS，当前秒
            fname = fullfile(obj.ctl.saver.save_fulldir, fname);   % 'C:\Users\Margrie_Lab1\Documents\raw_data\yyyymmddHHMM\yyyymmddHHMM_SS_001_themepark.mat'
            bin_fname = obj.ctl.saver.logging_fname();  % 'C:\Users\Margrie_Lab1\Documents\raw_data\yyyymmddHHMM\yyyymmddHHMM_SS_001.bin'
            
%             obj.ctl.vis_stim.off();
            obj.ctl.stop_acq();         % 停止NIDAQ的AI和CounterOutput
            obj.ctl.stop_sound();   
            
            protocol_name = obj.ctl.saver.index;
            n_trials = length(obj.stimulus_type_list);
            stimulus_type = obj.stimulus_type_list;
            response = obj.is_correct;
            
            save(fname, 'protocol_name', 'n_trials', 'stimulus_type', 'response');  % 保存''内变量到.mat文件
            
            try    
                AnalyzeAndPlotLickingData_DoubleRotation(bin_fname);   % 
            catch
            end
            
            delete(obj.h_listener_reward);
            
        end
    end
end