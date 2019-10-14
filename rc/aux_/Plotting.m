classdef Plotting < handle
    
    properties
        ni
        n_chans
        rate
        fig
        ax
        lines
        
        dur
        update_rate
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
        
        function obj = Plotting(ni, config)
            obj.ni = ni;
            
            obj.dur = config.plotting.time;
            obj.update_rate = config.plotting.update_rate;
            obj.downsample = 10;
            
            
            obj.n_chans = length(config.nidaq.ai.channel_names);
            obj.rate = config.nidaq.rate;
            
            obj.fig = figure();
            for i = 1 : obj.n_chans
                obj.ax(i) = subplot(obj.n_chans, 1, i);
                set(obj.ax(i), 'plotboxaspectratio', [10, 1, 1])
            end
        end
        
        
        function reset_vals(obj)
            obj.n_points_true = obj.dur * obj.rate;
            obj.true_t = (0:obj.n_points_true)/obj.rate;
            obj.plot_t = (0:obj.downsample:obj.n_points_true)/obj.rate;
            obj.n_points_plot = length(obj.plot_t);
            obj.current_t = 1;
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);
            obj.n_nan_points = obj.rate/obj.downsample;
            
            for i = 1 : obj.n_chans
                set(obj.fig, 'currentaxes', obj.ax(i));
                obj.lines(i) = line(obj.plot_t, obj.plot_data(:, i));
                set(obj.ax(i), 'xlim', obj.plot_t([1, end]), 'ylim', [-0.1, 5.1])
            end
        end
        
        
        function ni_callback(obj, ~, evt)
            
            current_plot_val = ceil(obj.current_t/obj.downsample);
            n_plot_points = obj.update_rate/obj.downsample;
            
            v_rep = current_plot_val + (0:n_plot_points);
            v_rep = mod(v_rep-1, obj.n_points_plot)+1;
            v_nan = current_plot_val + n_plot_points + (0:obj.n_nan_points);
            v_nan = mod(v_nan-1, obj.n_points_plot)+1;
            
            obj.plot_data(v_rep, :) = evt.Data;
            obj.plot_data(v_nan, :) = nan;
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i))
            end
            
            obj.current_t = mod(obj.current_t + obj.update_rate - 1, obj.n_points_true)+1;
        end
    end
end