function AnalyzeAndPlotLickingData_DoubleRotation(bin_fname)

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
LickDetect_trigger_chan_idx           = strcmp(channel_names, 'LickDetect_trigger');   
lick_chan_idx               = strcmp(channel_names, 'lick');                               
pump_chan_idx               = strcmp(channel_names, 'pump');  
visstim_chan_idx               = strcmp(channel_names, 'VisualStim_trigger');
photodiodeL_idx             = strcmp(channel_names, 'photodiode_left'); 
photodiodemid_idx           = strcmp(channel_names, 'photodiode_mid');
photodiodeR_idx             = strcmp(channel_names, 'photodiode_right');  

% time base of data
timebase                    = (0:size(data, 1)-1)*dt;

% signals
stage_central_signal        = data(:, stage_central_idx)*10;
stage_outer_signal          = data(:, stage_outer_idx)*10;
LickDetect_trigger_signal   = data(:, LickDetect_trigger_chan_idx);
photodiodeL_signal          = data(:, photodiodeL_idx);
photodiodeMid_signal        = data(:, photodiodemid_idx);
photodiodeR_signal          = data(:, photodiodeR_idx);
lick_signal                 = data(:, lick_chan_idx);
pump_signal                 = data(:, pump_chan_idx);
visstim_signal              = data(:, visstim_chan_idx);
% photodiode_signal           = data(:, photodiode_idx);

figure()
plot(timebase, stage_central_signal);
hold on;
plot(timebase, stage_outer_signal);
hold on;
plot(timebase, LickDetect_trigger_signal);
hold on;
plot(timebase, pump_signal);
hold on;
plot(timebase, lick_signal);
hold on;
plot(timebase, visstim_signal);
hold on;
plot(timebase, photodiodeL_signal);
hold on;
plot(timebase, photodiodeMid_signal);
hold on;
plot(timebase, photodiodeR_signal);
hold off;
legend('Central stage speed (deg/sec)','Outer stage speed (deg/sec)','LickDetect trigger','Pump','Lick','VisStim','Photodiode Left','Photodiode Mid','Photodiode Right');

% look for stimulus on
vis_stim_onset_flag         = diff(LickDetect_trigger_signal > vis_stim_threshold) == 1;
vis_stim_onset_time         = timebase(vis_stim_onset_flag);
n_trials                    = length(vis_stim_onset_time);

% print information about consistency
fprintf('Number of trials observed from raw data: %i\n', n_trials);

if online_data_exists
    
    fprintf('Number of trials in response .mat file: %i\n', online_data.n_trials);
    
    % if not equal issue a warning
    if n_trials ~= online_data.n_trials
        fprintf('Number of trials save to .mat file and number of expected trials from raw data do not match\n');
        
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
    %wasn't working so I converted to string - AA on 05/07/2021
    %s_plus_trial_idx            = strcmp(online_data.stimulus_type, 's_plus');
    %s_minus_trial_idx           = strcmp(online_data.stimulus_type, 's_minus');
    
    s_plus_trial_idx           = strcmp(string(online_data.stimulus_type), 's_plus');
    s_minus_trial_idx          = strcmp(string(online_data.stimulus_type), 's_minus');
else
    s_plus_trial_idx            = true(1, n_trials);
    s_minus_trial_idx           = false(1, n_trials);
end



%% PLOT

% lick rasters
figure();
h_ax_s_plus             = subplot(2, 1, 1);
hold on;
plot_raster(h_ax_s_plus, lick_times_relative(s_plus_trial_idx), vis_stim_duration);
set(h_ax_s_plus, 'xlim', padding);
if online_data_exists
    ylabel(h_ax_s_plus, 'S+ trial #');
    h_ax_s_minus = subplot(2, 1, 2);
    hold on;
    plot_raster(h_ax_s_minus, lick_times_relative(s_minus_trial_idx), vis_stim_duration);
    ylabel(h_ax_s_minus, 'S- trial #');
    set(h_ax_s_minus, 'xlim', padding);
else
    ylabel(h_ax_s_plus, 'Trial #');
end


% lick histograms
figure()
edges                   = padding(1):0.25:padding(2);
h_ax_s_plus = subplot(2, 1, 1);
hold on;
plot_histogram(h_ax_s_plus, lick_times_relative(s_plus_trial_idx), edges , vis_stim_duration);
set(h_ax_s_plus, 'xlim', padding);
if online_data_exists
    title(h_ax_s_plus, 'S+ trial');
    h_ax_s_minus = subplot(2, 1, 2);
    hold on;
    plot_histogram(h_ax_s_minus, lick_times_relative(s_minus_trial_idx), edges, vis_stim_duration);
    set(h_ax_s_minus, 'xlim', padding);
    title(h_ax_s_minus, 'S- trial');
else
    title(h_ax_s_plus, 'All trials');
end




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


