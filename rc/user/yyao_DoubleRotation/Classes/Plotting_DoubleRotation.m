classdef Plotting_DoubleRotation < handle
    

    properties
        n_chans
        chan_names
        chans_to_plot
        rate
        fig
        ax
        lines
        dur
        update_every
        downsample
        n_points_true
        true_t
        plot_t
        n_points_plot
        current_t
        plot_data
        n_nan_points
        ylim
        units
        ax_positions
    end
    


    methods
        function obj = Plotting_DoubleRotation(config)
            


            
            obj.dur = config.plotting.time;                                      % GUI实时绘图横轴(5秒)（在plotting_config_yyao中设置）
            obj.update_every = config.nidaq.log_every;                           % NIDAQ单位采样数据量(1000)
            obj.downsample = 10;                                                 % 降低采样倍率。以低于真实时间分辨率的精度绘图
            obj.chans_to_plot = config.plotting.chans_to_plot;                   % GUI实时绘图AI通道index(1:5)
            obj.chan_names = config.nidaq.ai.channel_names(obj.chans_to_plot);
            
            
            obj.n_chans = length(obj.chan_names);                                % GUI实时绘图通道数(5)
            obj.rate = config.nidaq.rate;                                        % NIDAQ采样频率(10000)
            
            obj.ylim = config.plotting.ylim;                                     % y轴数值{[-0.1, 5.1] , [-0.1, 5.1], [-0.1, 5.1] ,[-0.1, 5.1], [-0.1, 5.1]}
            obj.units = config.plotting.units;                                   % y轴单位{'V', 'V', 'V', 'V', 'V'};
            obj.ax_positions = config.plotting.ax_positions;
            
            obj.fig = figure();                                                  % 打开GUI实时绘图窗口
            set(obj.fig, 'position', config.plotting.fig.position);              % 设置GUI实时绘图窗口位置和大小
            set(obj.fig, 'closerequestfcn', @(x, y)obj.close_request(x, y));     % closerequestfcn，关闭请求回调。用户试图关闭图窗窗口时会执行该回调。回调close_request函数使窗口不可见
            set(obj.fig, 'color', [0, 0, 0]);
            
            for i = 1 : obj.n_chans
                obj.ax(i) = axes;                                                % 对每个通道设定x轴属性
                set(obj.ax(i), 'color', [0, 0, 0]);
                set(obj.ax(i), 'position', obj.ax_positions{i})
                if ~ismember(i, [4, obj.n_chans])
                    set(obj.ax(i), 'xtick', []);
                else
                    xlabel('Time (s)', 'color', 'w');
                end
            end
            
            obj.start_vals();
            obj.reset_vals();
        end
        
        
        function delete(obj)
            close(obj.fig);
            delete(obj.fig);
        end
        
        
        function close_request(obj, ~, ~)
            set(obj.fig, 'visible', 'off');  %  隐藏对象而不删除它
        end
        
        
        function start_vals(obj)
            
            obj.n_points_true = obj.dur * obj.rate;   % 5*10000=50000
            obj.true_t = (0:obj.n_points_true)/obj.rate;   % 实时绘图真实时间变量。真实时间分辨率为0.0001秒
            obj.plot_t = (0:obj.downsample:obj.n_points_true)/obj.rate;  % 实时绘图绘制时间变量，每隔10个点绘制一个点。即绘图时间分辨率为0.001秒
            
            obj.n_points_plot = length(obj.plot_t);                   % 绘图点数
            obj.current_t = 1;                                        %
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);      % 绘图数据初始化为NaN
            obj.n_nan_points = obj.rate/obj.downsample;               % NaN点数(1000)
            
            cols = lines(obj.n_chans); %#ok<CPROP>
            for i = 1 : obj.n_chans
                set(obj.fig, 'currentaxes', obj.ax(i));               % 设置当前坐标区对象为相应通道绘图区的x轴
                obj.lines(i) = line(obj.plot_t, obj.plot_data(:, i), 'color', cols(i, :));  % 使用向量obj.plot_t和obj.plot_data(:, i)中的数据在当前坐标区中绘制线条。
                set(obj.ax(i), 'xlim', obj.plot_t([1, end]), 'ylim', obj.ylim{i});
                set(obj.ax(i), 'ycolor', 'w', 'xcolor', 'w');
                ylabel(obj.units{i}, 'color', 'w');
                title(obj.chan_names{i}, 'fontsize', 8, 'interpreter', 'none', 'color', [1, 1, 1]);
            end
        end
        
        
        function reset_vals(obj)   % 重置实时绘图窗口变量
            
            set(obj.fig, 'visible', 'on');   % 设置绘图窗口强制可见
            
            obj.current_t = 1;
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i));  % 传递用于绘图的y轴数据，并更新绘图
            end
        end
        
        
        function ni_callback(obj, data)      % 更新并绘制NIDAQ采样数据
            
            current_plot_val = ceil(obj.current_t/obj.downsample);   % 计算当前绘图对应的时间轴定位
            n_plot_points = obj.update_every/obj.downsample;         % 1000/10=100。NIDAQ单位采样数据对应的绘图点数
            
            v_rep = current_plot_val + (0:n_plot_points-1);          % 100个绘图点对应的时间轴定位
            v_rep = mod(v_rep-1, obj.n_points_plot)+1;
            v_nan = current_plot_val + n_plot_points + (0:obj.n_nan_points-1);  % 其后用NaN补全的时间轴定位
            v_nan = mod(v_nan-1, obj.n_points_plot)+1;
            
            if size(data, 1) < 100
                return
            end
            
            obj.plot_data(v_rep, :) = data(1:10:end, obj.chans_to_plot);  % 提取绘图用y轴数据（第1,11,21,...991采样点）
            obj.plot_data(v_nan, :) = nan;                                % 用NaN补全其后空白
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i))           % 传递用于绘图的y轴数据，并更新绘图
            end
            
            obj.current_t = mod(obj.current_t + obj.update_every - 1, obj.n_points_true)+1;  % 移动当前绘图对应的时间轴定位
        end
    end
end