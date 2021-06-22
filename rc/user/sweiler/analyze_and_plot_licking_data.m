function analyze_and_plot_licking_data(bin_fname)

% padding around visual onset
padding                     = [-5, 3];
vis_stim_threshold          = 2.5;
pump_threshold              = 2.5;
lick_threshold              = 2;

% load the raw data and online data (if it exists)
mat_fname                   = strrep(bin_fname, '.bin', '_themepark.mat');

[data, ~, channel_names, ~] = read_rc2_bin(bin_fname);
online_data_exists          = isfile(mat_fname);

if online_data_exists
    online_data                 = load(mat_fname);
end

% channel id of various signals
vis_stim_chan_idx           = strcmp(channel_names, 'visual_stimulus_computer_minidaq');
lick_chan_idx               = strcmp(channel_names, 'lick');
pump_chan_idx               = strcmp(channel_names, 'pump');
% photodiode_idx              = strcmp(channel_names, 'photodiode_left');

% time base of data
timebase                    = (0:size(data, 1)-1)*dt;

% signals
vis_stim_signal             = data(:, vis_stim_chan_idx);
lick_signal                 = data(:, lick_chan_idx);
pump_signal                 = data(:, pump_chan_idx);
% photodiode_signal           = data(:, photodiode_idx);

% look for stimulus on
vis_stim_onset_flag         = diff(vis_stim_signal > vis_stim_threshold) == 1;
vis_stim_onset_time         = timebase(vis_stim_onset_flag);
n_trials                    = length(vis_stim_onset_time);

% print information about consistency
fprintf('Number of trials observed from raw data: %i\n', n_trials);

if online_data_exists
    
    fprintf('Number of trials in response .mat file: %i\n', online_data.n_trials);
    
    % if not equal issue a warning
    if n_trials ~= online_data.n_trials
        warning('Number of trials save to .mat file and number of expected trials from raw data do not match');
    end
end

% 
pump_onset_flag             = diff(pump_signal > pump_threshold) == 1;
fprintf('Number of rewards given: %i\n', sum(pump_onset_flag));

% detect lick thresholds
lick_onset_flag             = diff(lick_signal > lick_threshold) == 1;
lick_onset_time             = timebase(lick_onset_flag);


% % for each trial get licks around vis_stim onset
lick_times_relative = cell(n_trials, 1);
for i = 1 : n_trials
    these_licks = lick_onset_time > vis_stim_onset_time(i) + padding(1) & ...
                    lick_onset_time < vis_stim_onset_time(i) + padding(2);
    lick_times_relative{i} = lick_onset_time(these_licks) - vis_stim_onset_time(i);
end

% index of s+ and s- trials
if online_data_exists
    s_plus_trial_idx            = strcmp(online_data.stimulus_type, 's_plus');
    s_minus_trial_idx           = strcmp(online_data.stimulus_type, 's_minus');
else
    s_plus_trial_idx            = true(1, n_trials);
    s_minus_trial_idx           = false(1, n_trials);
end



%% PLOT

% lick rasters
figure();
h_ax_s_plus             = subplot(2, 1, 1);
plot_raster(h_ax_s_plus, lick_times_relative(s_plus_trial_idx));
if online_data_exists
    ylabel(h_ax_s_plus, 'S+ trial #');
    h_ax_s_minus = subplot(2, 1, 2);
    plot_raster(h_ax_s_minus, lick_times_relative(s_minus_trial_idx));
    ylabel(h_ax_s_minus, 'S- trial #');
    
else
    ylabel(h_ax_s_plus, 'Trial #');
end


% lick histograms
figure()
edges                   = padding(1):0.25:padding(2);
h_ax_s_plus = subplot(2, 1, 1);
plot_histogram(h_ax_s_plus, lick_times_relative(s_plus_trial_idx), edges);
if online_data_exists
    title(h_ax_s_plus, 'S+ trial');
    h_ax_s_minus = subplot(2, 1, 2);
    plot_histogram(h_ax_s_minus, lick_times_relative(s_minus_trial_idx), edges);
    title(h_ax_s_minus, 'S- trial');
else
    title(h_ax_s_plus, 'All trials');
end




function plot_raster(h_ax, lick_times)

fill(h_ax, [0, 2, 2, 0], [0, 0, length(lick_times), length(lick_times)], [0.7, 0.7, 0.7]);
for i = 1 : length(lick_times)
    n_licks = length(lick_times{i});
    scatter(h_ax, lick_times{i}, i*ones(1, n_licks), [], 'k', 'fill');
end
line(h_ax, [0, 0], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
line(h_ax, [2, 2], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
xlabel(h_ax, 'Time (s)');
set(h_ax, 'ylim', [0, length(lick_times)+1], 'plotboxaspectratio', [1, 2, 1]);



function plot_histogram(h_ax, lick_times, edges)

fill(h_ax, [0, 2, 2, 0], [0, 0, length(lick_times), length(lick_times)], [0.7, 0.7, 0.7]);
histogram(h_ax, [lick_times{:}], edges);
line(h_ax, [0, 0], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
line(h_ax, [2, 2], get(h_ax, 'ylim'), 'color', 'k', 'linestyle', '--');
set(h_ax, 'plotboxaspectratio', [1, 2, 1]);
xlabel(h_ax, 'Time (s)');


