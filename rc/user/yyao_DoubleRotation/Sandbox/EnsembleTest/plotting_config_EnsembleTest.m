function config = plotting_config_EnsembleTest()
%%config = PLOTTING_CONFIG_SWEILER()
% Configuration settings for display of traces.

config.time = 5;   
config.fig.position = [1100, 550, 800, 400];  
config.chans_to_plot = 1:4;   
config.ylim = {[-10.1, 10.1] , [-10.1, 10.1], [-2.1, 2.1] ,[-2.1, 2.1]};
config.units = {'V', 'V', 'V', 'V'};
config.ax_positions = {[0.03, 0.80, 0.45, 0.17], ...
                    [0.03, 0.56, 0.45, 0.17], ...
                    [0.03, 0.32, 0.45, 0.17], ...
                    [0.03, 0.08, 0.45, 0.17], };
