classdef GoNogo_DoubleRotation_GUIController < handle
    
    properties
        
        protocol
        view
    end
    
    
    methods
        
        function obj = GoNogo_DoubleRotation_GUIController(protocol)
            
            obj.protocol = protocol;      % ProtocolSequence类变量
            obj.view = GoNogo_DoubleRotation_GUIView(obj);  % 将protocol属性值作为参数传递，调用GoNogo_DoubleRotation_GUIView类的构造函数，打开GUI界面（GoNogo_DoubleRotation_GUI.mlapp文件）。obj.view即为GUI界面
                                              % 将GoNogo_DoubleRotation_GUIView类变量（包含controller和gui属性，其中gui属性的值为ProtocolGUI'类变量'，下包括多个'属性'）赋值给obj.view属性。
            addlistener(obj.protocol, 'current_trial', 'PostSet', @(src, evnt)obj.current_trial_updated(src, evnt));
            addlistener(obj.protocol, 'n_correct_s_plus_trials', 'PostSet', @(src, evnt)obj.n_correct_s_plus_updated(src, evnt));
            addlistener(obj.protocol, 'n_incorrect_s_plus_trials', 'PostSet', @(src, evnt)obj.n_incorrect_s_plus_updated(src, evnt));
            addlistener(obj.protocol, 'n_correct_s_minus_trials', 'PostSet', @(src, evnt)obj.n_correct_s_minus_updated(src, evnt));
            addlistener(obj.protocol, 'n_incorrect_s_minus_trials', 'PostSet', @(src, evnt)obj.n_incorrect_s_minus_updated(src, evnt));
            addlistener(obj.protocol, 'n_rewards_given', 'PostSet', @(src, evnt)obj.n_rewards_given_updated(src, evnt));
            
            set(obj.view.gui.s_plus_axes, 'ylim', [-0.05, 1.05], 'ytick', [0, 1]);  % 配置GUI界面的s_plus_axes对象的YLim和YTick属性值（S+ trial绘图横纵坐标轴范围）
            set(obj.view.gui.s_minus_axes, 'ylim', [-0.05, 1.05], 'ytick', [0, 1]); % 配置GUI界面的s_minus_axes对象的YLim和YTick属性值（S- trial绘图横纵坐标轴范围）
            obj.view.gui.warning_text.Text = '';                                    % 配置GUI界面的warning_text对象的Text属性的值
        end
        
        
        
        function delete(obj)
            delete(obj.view);
            if isvalid(obj.protocol)
                obj.protocol.stop();
            end
        end
        
        
        function stop_protocol(obj)
            obj.protocol.stop();
        end
        
        
        function current_trial_updated(obj, ~, ~)
            obj.view.gui.current_trial_val.Text = sprintf('%i', obj.protocol.current_trial);  % 更新GUI界面的current_trial_val对象的Text属性的值（current trial编号显示）
        end
        
        function n_correct_s_plus_updated(obj, ~, ~)
            obj.view.gui.s_plus_correct_val.Text = sprintf('%i', obj.protocol.n_correct_s_plus_trials);  % 更新GUI界面S+ trial正确trial数显示
            obj.update_plot();
        end
        
        function n_incorrect_s_plus_updated(obj, ~, ~)
            obj.view.gui.s_plus_incorrect_val.Text = sprintf('%i', obj.protocol.n_incorrect_s_plus_trials);  % 更新GUI界面S+ trial错误trial数显示
            obj.update_plot();
        end
        
        function n_correct_s_minus_updated(obj, ~, ~)
            obj.view.gui.s_minus_correct_val.Text = sprintf('%i', obj.protocol.n_correct_s_minus_trials);  % 更新GUI界面S- trial正确trial数显示
            obj.update_plot();
        end
        
        function n_incorrect_s_minus_updated(obj, ~, ~)
            obj.view.gui.s_minus_incorrect_val.Text = sprintf('%i', obj.protocol.n_incorrect_s_minus_trials);  % 更新GUI界面S- trial错误trial数显示
            obj.update_plot();
        end
        
        function n_rewards_given_updated(obj, ~, ~)
            obj.view.gui.total_rewards_given.Text = sprintf('%i', obj.protocol.n_rewards_given);  % 更新GUI界面总奖励数显示
        end
        
        function update_plot(obj)    % 更新绘图
            
            s_plus_idx = cellfun(@(x)(strcmp(x,'s_plus')), obj.protocol.stimulus_type_list);
            s_minus_idx = cellfun(@(x)(strcmp(x,'s_minus')), obj.protocol.stimulus_type_list);
            
            n_s_plus = sum(s_plus_idx);
            n_s_minus = sum(s_minus_idx);
            
            s_plus_response = obj.protocol.is_correct(s_plus_idx);
            s_minus_response = obj.protocol.is_correct(s_minus_idx);
            
            s_plus_col = zeros(n_s_plus, 3);
            s_plus_col(s_plus_response == 0, 1) = 1;
            s_plus_col(s_plus_response == 1, 3) = 1;
            
            s_minus_col = zeros(n_s_minus, 3);
            s_minus_col(s_minus_response == 0, 1) = 1;
            s_minus_col(s_minus_response == 1, 3) = 1;
            
            scatter(obj.view.gui.s_plus_axes, 1:n_s_plus, s_plus_response, [], s_plus_col, 'fill');       % 在GUI界面s_plus_axes对象绘制散点图
            scatter(obj.view.gui.s_minus_axes, 1:n_s_minus, s_minus_response, [], s_minus_col, 'fill');   % 在GUI界面s_minus_axes对象绘制散点图
            
            set(obj.view.gui.s_plus_axes, 'xlim', [0, n_s_plus+1], 'xtick', 1:n_s_plus)
            set(obj.view.gui.s_minus_axes, 'xlim', [0, n_s_minus+1], 'xtick', 1:n_s_minus)
            
            if length(s_plus_response) >= 3
                if sum(s_plus_response(end-2:end)) == 0
                    obj.view.gui.warning_text.Text = '3 incorrect S+ trials in a row';
                end
            end
        end
    end
end
