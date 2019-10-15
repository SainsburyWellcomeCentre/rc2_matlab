classdef Plotting < handle
    
    properties
        n_chans
        chan_names
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
    end
    
    methods
        
        function obj = Plotting(config)
            
            obj.dur = config.plotting.time;
            obj.update_every = config.nidaq.log_every;
            obj.downsample = 10;
            obj.chan_names = config.nidaq.ai.channel_names;
            
            obj.n_chans = length(obj.chan_names);
            obj.rate = config.nidaq.rate;
            
            obj.fig = figure();
            set(obj.fig, 'position', config.plotting.fig.position);
            set(obj.fig, 'closerequestfcn', @(x, y)obj.close_request(x, y));
            for i = 1 : obj.n_chans
                obj.ax(i) = subplot(obj.n_chans, 1, i);
                set(obj.ax(i), 'plotboxaspectratio', [20, 1, 1]);
                p = get(obj.ax(i), 'position');
                p([1, 3]) = [0.05, 0.9];
                if i ~= obj.n_chans
                    set(obj.ax(i), 'xtick', []);
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
            set(obj.fig, 'visible', 'off');
        end
        
        
        function start_vals(obj)
            
            obj.n_points_true = obj.dur * obj.rate;
            obj.true_t = (0:obj.n_points_true)/obj.rate;
            obj.plot_t = (0:obj.downsample:obj.n_points_true)/obj.rate;
            
            obj.n_points_plot = length(obj.plot_t);
            obj.current_t = 1;
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);
            obj.n_nan_points = obj.rate/obj.downsample;
            
            cols = lines(obj.n_chans); %#ok<CPROP>
            for i = 1 : obj.n_chans
                set(obj.fig, 'currentaxes', obj.ax(i));
                obj.lines(i) = line(obj.plot_t, obj.plot_data(:, i), 'color', cols(i, :));
                set(obj.ax(i), 'xlim', obj.plot_t([1, end]), 'ylim', [-0.1, 5.1]);
                set(obj.ax(i), 'tickdir', 'out');
                title(obj.chan_names{i}, 'fontsize', 8, 'interpreter', 'none');
            end
        end
        
        
        function reset_vals(obj)
            
            set(obj.fig, 'visible', 'on');
            
            obj.current_t = 1;
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i));
            end
        end
        
        
        function ni_callback(obj, data)
            
            current_plot_val = ceil(obj.current_t/obj.downsample);
            n_plot_points = obj.update_every/obj.downsample;
            
            v_rep = current_plot_val + (0:n_plot_points-1);
            v_rep = mod(v_rep-1, obj.n_points_plot)+1;
            v_nan = current_plot_val + n_plot_points + (0:obj.n_nan_points-1);
            v_nan = mod(v_nan-1, obj.n_points_plot)+1;
            
            obj.plot_data(v_rep, :) = data(1:10:end, :);
            obj.plot_data(v_nan, :) = nan;
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i))
            end
            
            obj.current_t = mod(obj.current_t + obj.update_every - 1, obj.n_points_true)+1;
        end
    end
end