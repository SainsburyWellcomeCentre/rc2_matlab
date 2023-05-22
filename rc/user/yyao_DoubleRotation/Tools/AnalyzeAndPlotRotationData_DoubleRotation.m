function data = AnalyzeAndPlotRotationData_DoubleRotation(bin_fname)

% padding around visual onset
padding                     = [-3, 5];
vis_stim_duration           = 4;
vis_stim_threshold          = 2.5;
pump_threshold              = 2.5;
lick_threshold              = 2;

% load the raw data and online data (if it exists)
mat_fname                   = strrep(bin_fname, '.bin', '_themepark.mat');  

[data, dt, channel_names, ~] = read_rc2_bin(bin_fname);   
online_data_exists          = isfile(mat_fname);

if online_data_exists
    online_data                 = load(mat_fname);   
end

% channel id of various signals
stage_central_idx           = strcmp(channel_names, 'stage_central');   
stage_outer_idx           = strcmp(channel_names, 'stage_outer');  


% time base of data
timebase                    = (0:size(data, 1)-1)*dt;

% signals
stage_central_signal        = data(:, stage_central_idx);
stage_outer_signal          = data(:, stage_outer_idx);


figure()
plot(timebase, stage_central_signal);
hold on;
plot(timebase, stage_outer_signal);
hold off;
legend('Central stage speed (V)','Outer stage speed (V)');




function plot_raster(h_ax, lick_times, vis_stim_duration)

fill(h_ax, [0, vis_stim_duration, vis_stim_duration, 0], [0, 0, length(lick_times), length(lick_times)], [0.7, 0.7, 0.7]);
for i = 1 : length(lick_times)
    n_licks = length(lick_times{i});
    scatter(h_ax, lick_times{i}, i*ones(1, n_licks), 5 , 'k', 'fill');
end
line(h_ax, [0, 0], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
line(h_ax, [2, 2], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
xlabel(h_ax, 'Time (s)');
set(h_ax, 'ylim', [0, length(lick_times)+1], 'plotboxaspectratio', [2, 1, 1]);



function plot_histogram(h_ax, lick_times, edges, vis_stim_duration)

fill(h_ax, [0, vis_stim_duration, vis_stim_duration, 0], [0, 0, length(lick_times), length(lick_times)], [0.7, 0.7, 0.7]);
histogram(h_ax, [lick_times{:}], edges);
line(h_ax, [0, 0], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
line(h_ax, [vis_stim_duration, vis_stim_duration], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
set(h_ax, 'plotboxaspectratio', [2, 1, 1]);
xlabel(h_ax, 'Time (s)');


