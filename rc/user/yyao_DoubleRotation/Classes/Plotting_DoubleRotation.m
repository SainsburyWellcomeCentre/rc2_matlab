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

            obj.dur = config.plotting.time;                                      
            obj.update_every = config.nidaq.log_every;                           
            obj.downsample = 10;                                                 
            obj.chans_to_plot = config.plotting.chans_to_plot;                   % AI channel index to plot
            obj.chan_names = config.nidaq.ai.channel_names(obj.chans_to_plot);
            
            
            obj.n_chans = length(obj.chan_names);                                
            obj.rate = config.nidaq.rate;                                        % NIDAQ sampling rate(10000)
            
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
                if ~ismember(i, [5, obj.n_chans])                                
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
            set(obj.fig, 'visible', 'off');  %  hide instead of close
        end
        
        
        function start_vals(obj)
            
            obj.n_points_true = obj.dur * obj.rate;   % 5*10000=50000
            obj.true_t = (0:obj.n_points_true)/obj.rate;   % true time (resolution 0.0001 sec)
            obj.plot_t = (0:obj.downsample:obj.n_points_true)/obj.rate;  % plot time (resolution 0.001 sec)
            
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