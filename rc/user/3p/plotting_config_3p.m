function config = plotting_config_3p()
%%config = PLOTTING_CONFIG()
% Configuration settings for display of traces.


config.time = 5; %s
config.fig.position = [100, 0, 1333, 630];
config.chans_to_plot = 1:5;
config.ylim = {[-0.1, 5.1], [-0.1, 5.1], [-0.1, 5.1], [-0.1, 5.1] , [-0.1, 5.1]};
config.units = {'V', 'V', 'V', 'V', 'V'};
config.ax_positions = {[0.03, 0.54, 0.45, 0.19], ...
                    [0.03, 0.3, 0.45, 0.19], ...
                    [0.03, 0.06, 0.45, 0.19], ...
                    [0.53, 0.78, 0.45, 0.19],...
                    [0.53, 0.54, 0.45, 0.19]};
