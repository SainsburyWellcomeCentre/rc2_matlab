classdef Plotting < handle
    % Plotting class for plotting the data being acquired.

    properties (SetAccess = private)
        n_chans % The total number of channels being acquired.
        chan_names % Names of the channels being acquired.
        chans_to_plot % Indices of the channels to plot.
        rate % Sampling rate of the analog input.
        fig % Handle to the figure.
        ax % Handle to all the figure axes.
        lines % Handle to the data plots on the axes.
        dur % Time window to plot in a figure, in seconds (size of x-axis).
        update_every % How often to update the plot, in seconds.
        downsample % Downsampling factor, only plot every n points.
        n_points_true % If not downsampled, how many points would be plotted on the axes.
        true_t % Unused.
        plot_t % Time base of the downsampled plotted data.
        n_points_plot % Number of points to plot.
        current_t % Current time of the last data point.
        plot_data % Data in the current plot.
        n_nan_points % Number of points to make NaN.
        ylim % Y-axis limits.
        units % Units of the y-axis.
        ax_positions % Positions of the axes.
    end
    
    
    
    methods
        function obj = Plotting(config)
            % Constructor for a :class:`rc.classes.Plotting` class.
            %
            % :param config: The main configuration structure.
        
            obj.dur = config.plotting.time;
            obj.update_every = config.nidaq.log_every;
            obj.downsample = 10;
            obj.chans_to_plot = config.plotting.chans_to_plot;
            obj.chan_names = config.nidaq.ai.channel_names(obj.chans_to_plot);
            
            
            obj.n_chans = length(obj.chan_names);
            obj.rate = config.nidaq.rate;
            
            obj.ylim = config.plotting.ylim;
            obj.units = config.plotting.units;
            obj.ax_positions = config.plotting.ax_positions;
            
            obj.fig = figure();
            set(obj.fig, 'position', config.plotting.fig.position);
            set(obj.fig, 'closerequestfcn', @(x, y)obj.close_request(x, y));
            set(obj.fig, 'color', [0, 0, 0]);
            
            for i = 1 : obj.n_chans
                obj.ax(i) = axes;
                set(obj.ax(i), 'color', [0, 0, 0]);
                set(obj.ax(i), 'position', obj.ax_positions{i})
                if ~ismember(i, [3, obj.n_chans])
                    set(obj.ax(i), 'xtick', []);
                else
                    xlabel('Time (s)', 'color', 'w');
                end
            end
            
            obj.start_vals();
            obj.reset_vals();
        end
        
        
        
        function delete(obj)
            % Destructor for :class:`rc.classes.Plotting` class.
        
            close(obj.fig);
            delete(obj.fig);
        end
        
        
        
        function close_request(obj, ~, ~)
            % Hide the figure, don't close.
        
            set(obj.fig, 'visible', 'off');
        end
        
        
        
        function start_vals(obj)
            % Setup the starting values of the properties on object creation.
        
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
                set(obj.ax(i), 'xlim', obj.plot_t([1, end]), 'ylim', obj.ylim{i});
                set(obj.ax(i), 'ycolor', 'w', 'xcolor', 'w');
                ylabel(obj.units{i}, 'color', 'w');
                title(obj.chan_names{i}, 'fontsize', 8, 'interpreter', 'none', 'color', [1, 1, 1]);
            end
        end
        
        
        
        function reset_vals(obj)
            % Reset the values of the properties between acquisitions.
        
            set(obj.fig, 'visible', 'on');
            
            obj.current_t = 1;
            obj.plot_data = nan(obj.n_points_plot, obj.n_chans);
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i));
            end
        end
        
        
        
        function ni_callback(obj, data)
            % Callback function which updates the plot during acquisition. Selects channels to plot, downsamples and adds data to plot.
            %
            % :param data: N x :attr:`n_chan` matrix of data.
        
            current_plot_val = ceil(obj.current_t/obj.downsample);
            n_plot_points = obj.update_every/obj.downsample;
            
            v_rep = current_plot_val + (0:n_plot_points-1);
            v_rep = mod(v_rep-1, obj.n_points_plot)+1;
            v_nan = current_plot_val + n_plot_points + (0:obj.n_nan_points-1);
            v_nan = mod(v_nan-1, obj.n_points_plot)+1;
            
            if size(data, 1) < 100
                return
            end
            
            obj.plot_data(v_rep, :) = data(1:10:end, obj.chans_to_plot);
            obj.plot_data(v_nan, :) = nan;
            
            for i = 1 : obj.n_chans
                set(obj.lines(i), 'ydata', obj.plot_data(:, i))
            end
            
            obj.current_t = mod(obj.current_t + obj.update_every - 1, obj.n_points_true)+1;
        end
    end
end
