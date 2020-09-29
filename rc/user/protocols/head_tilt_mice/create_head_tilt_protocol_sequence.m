function [trial_order, fnames, protocol_id] = create_head_tilt_protocol_sequence()
% Create trial sequence for the "head-tilt" mice. This consists of:
%
%   1. vestibular motion with visual flow 
%   2. vestibular motion in darkness
%   3. visual flow (no vestibular motion)
%
%   All motion comes from saved velocity profiles
%
%   The sequence occurs in batches (i.e. each type of trial is played once,
%   before the next batch)
%   Within each batch the trials are randomized.
%   
%   Files are randomized across *all* trials.
%
%   trial_order - sequence of trials
%   protocol_id - structure containing ID of each trial type



% restart random number generator
rng(1)

% data location
data_dir = fullfile(pwd, 'head_tilt_waveforms');

% location of waveform presentation order
vis_flow_list_fname = fullfile(data_dir, 'visual_flow_presentation_order.txt');
darkness_list_fname = fullfile(data_dir, 'darkness_presentation_order.txt');

% create fid
fid_vis_flow = fopen(vis_flow_list_fname, 'r');
fid_darkness = fopen(darkness_list_fname, 'r');

% read presentation orders
vis_flow_str = fread(fid_vis_flow, '*char')';
darkness_str = fread(fid_darkness, '*char')';

% close files
fclose(fid_vis_flow);
fclose(fid_darkness);

% split the strings
vis_flow_fnames = strsplit(vis_flow_str, ',');
darkness_fnames = strsplit(darkness_str, ',');

% prepend the data location
vis_flow_fnames = cellfun(@(x)(fullfile(data_dir, x)), vis_flow_fnames, 'uniformoutput', false);
darkness_fnames = cellfun(@(x)(fullfile(data_dir, x)), darkness_fnames, 'uniformoutput', false);

% list of protocols
protocol_id.vest_with_flow      = 1;
protocol_id.visual_flow         = 2;
protocol_id.vest_darkness       = 3;

% number of trials in each protocol
n_trials = [length(vis_flow_fnames), length(vis_flow_fnames), length(darkness_fnames)];

% 
trial_order_ = repmat((1:3)', 1, max(n_trials));
file_no_ = repmat((1:max(n_trials)), 3, 1);


for i = 1 : 3
    trial_order_(i, (n_trials(i)+1):end) = nan;
    file_no_(i, (n_trials(i)+1):end) = nan;
end

% randomize across repeats
for i = 1 : 3
    I = randperm(max(n_trials));
    trial_order_(i, :) = trial_order_(i, I);
    file_no_(i, :) = file_no_(i, I);
end


% randomize across batches
for i = 1 : max(n_trials)
    I = randperm(3);
    trial_order_(:, i) = trial_order_(I, i);
    file_no_(:, i) = file_no_(I, i);
end


% vectorize the order
trial_order = trial_order_(:);
file_no = file_no_(:);

% remove nan values
trial_order(isnan(trial_order)) = [];
file_no(isnan(file_no)) = [];

% 
fnames = cell(length(file_no), 1);

% 
for i = 1 : length(trial_order)
    
    if trial_order(i) == protocol_id.vest_with_flow
        fnames{i} = fullfile(data_dir, vis_flow_fnames{file_no(i)});
    elseif trial_order(i) == protocol_id.visual_flow
        fnames{i} = fullfile(data_dir, vis_flow_fnames{file_no(i)});
    elseif trial_order(i) == protocol_id.vest_darkness
        fnames{i} = fullfile(data_dir, darkness_fnames{file_no(i)});
    end
end
