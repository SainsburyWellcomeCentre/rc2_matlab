function analyze_and_plot_licking_data_aa(bin_fname,animal_id, block_idx, dname)
%Adapted from Lee on July 2021

save_figs = true;

if block_idx > 60

    
    % padding around visual onset
if block_idx > 44
    padding                     = [-11, 5];
else
    padding                     = [-5, 3];
end

if block_idx >60
    vis_stim_duration           = 4;
else
    vis_stim_duration           = 2;
end


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

%animal_id  = string(bin_fname(43:53));
%block_idx = bin_fname(67:68);
%id_session = bin_fname(55:68);
%dname = string(strcat('C:\Users\Margrie_Lab1\Documents\temp_data\', animal_id));
id_session = strcat(animal_id,' Block ', string(block_idx));



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

figure('Name', id_session, 'NumberTitle', 'off');
plot(timebase, vis_stim_signal);
hold on;
plot(timebase, lick_signal);
plot(timebase, pump_signal);
title(id_session)
if save_figs == true
    saveas(gcf, fullfile(dname, strcat(id_session, '_all_data')), 'png');
else
end

% look for stimulus on
vis_stim_onset_flag         = diff(vis_stim_signal > vis_stim_threshold) == 1;
vis_stim_onset_time         = timebase(vis_stim_onset_flag);
n_trials                    = length(vis_stim_onset_time);

% print information about consistency
fprintf('Number of trials observed from raw data: %i\n', n_trials);

if online_data_exists
    
    fprintf('Number of trials in response .mat file: %i\n', online_data.n_trials);
    protocol_n = strcat('Protocol ', num2str(online_data.protocol_number));
    %total_water = integrate_amount_of_water_given(dname, block_idx, animal_id);
    
    % if not equal issue a warning
    if online_data.n_trials == 0
        warning('Number of trials save to .mat file is 0 and number of expected trials from raw data do not match');
        fprintf('In %i\n', block_idx)
    else
        n_trials ~= online_data.n_trials & online_data.n_trials > 0
        warning('Number of trials save to .mat file and number of expected trials from raw data do not match, excluding first trial');
        online_data.n_trials (:,1)       = online_data.n_trials - 1;
        online_data.stimulus_type(:,1)   = [];
        online_data.response (:,1)       = [];
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
    
    s_plus_trial_idx           = strcmp(string(online_data.stimulus_type), 's_plus');
    s_minus_trial_idx          = strcmp(string(online_data.stimulus_type), 's_minus');
  
else
    s_plus_trial_idx            = true(1, n_trials);
    s_minus_trial_idx           = false(1, n_trials);
end



%% PLOT

% lick rasters
figure('Name', id_session, 'NumberTitle', 'off');
h_ax_s_plus             = subplot(2, 1, 1);
hold on;
plot_raster(h_ax_s_plus, lick_times_relative(s_plus_trial_idx), vis_stim_duration);
set(h_ax_s_plus, 'xlim', padding);
if online_data_exists
    ylabel(h_ax_s_plus, 'S+ trial #');
    if sum(s_minus_trial_idx)> 0
    h_ax_s_minus = subplot(2, 1, 2);
    hold on;
    plot_raster(h_ax_s_minus, lick_times_relative(s_minus_trial_idx), vis_stim_duration);
    ylabel(h_ax_s_minus, 'S- trial #');
    set(h_ax_s_minus, 'xlim', padding);
    annotation('textbox', [.8 .9 .1 .1],'String',protocol_n, 'EdgeColor', 'none');
    %annotation('textbox', [.8 .85 .1 .1], 'String',strcat(num2str(total_water), 'ul') , 'EdgeColor', 'none');
    else
    annotation('textbox', [.8 .9 .1 .1],'String',protocol_n, 'EdgeColor', 'none');
    %annotation('textbox', [.8 .85 .1 .1], 'String',strcat(num2str(total_water), 'ul') , 'EdgeColor', 'none');
    end
else
    ylabel(h_ax_s_plus, 'Trial #');
end
title(strrep(id_session, '_', ' block '))
   
if save_figs == true
    saveas(gcf, fullfile(dname, strcat(id_session, '_lick_raster')), 'png');
else
end

% lick histograms
figure('Name', id_session, 'NumberTitle', 'off');
edges                   = padding(1):0.25:padding(2);
h_ax_s_plus = subplot(2, 1, 1);
hold on;
plot_histogram(h_ax_s_plus, lick_times_relative(s_plus_trial_idx), edges, vis_stim_duration);
set(h_ax_s_plus, 'xlim', padding);
if online_data_exists
    subtitle(h_ax_s_plus, 'S+ trial');
    if sum(s_minus_trial_idx) > 0
    h_ax_s_minus = subplot(2, 1, 2);
    hold on;
    plot_histogram(h_ax_s_minus, lick_times_relative(s_minus_trial_idx), edges, vis_stim_duration);
    set(h_ax_s_minus, 'xlim', padding);
    subtitle(h_ax_s_minus, 'S- trial');
    annotation('textbox', [.8 .9 .1 .1],'String',protocol_n, 'EdgeColor', 'none');
    %annotation('textbox', [.8 .85 .1 .1], 'String',strcat(num2str(total_water), 'ul') , 'EdgeColor', 'none');
    else
    annotation('textbox', [.8 .9 .1 .1],'String',protocol_n, 'EdgeColor', 'none');
    %annotation('textbox', [.8 .85 .1 .1], 'String',strcat(num2str(total_water), 'ul') , 'EdgeColor', 'none');
    end
else
    subtitle(h_ax_s_plus, 'All trials');
end
title(strrep(id_session, '_', ' block '));
  
if save_figs == true
    saveas(gcf, fullfile(dname, strcat(id_session, '_lick_histo')), 'png');
else
end



else
end


function plot_raster(h_ax, lick_times, vis_stim_duration)

fill(h_ax, [0, vis_stim_duration, vis_stim_duration, 0], [0, 0, length(lick_times), length(lick_times)], [0.7, 0.7, 0.7]);
for i = 1 : length(lick_times)
    n_licks = length(lick_times{i});
    scatter(h_ax, lick_times{i}, i*ones(1, n_licks), [], 'k', 'fill');
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

