function [trial_order, fnames, protocol_id] = create_passive_protocol_sequence_motion_clouds()
% Create trial sequence for the "passive" mice. This consists of:
%
%   1. vestibular motion with visual flow 
%   2. vestibular motion in darkness (or with visual static Tvs)
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

% number of trials in each protocol
n_trials = 37; % number of motion clouds

% data location
data_dir = fullfile(pwd, 'passive_waveforms_motion_clouds');

track_fnames = dir(fullfile(data_dir, '*.bin'));
track_fnames = {track_fnames(:).name};
num_speed_profiles = length(track_fnames);  % Number of speed profiles

% list of protocols
protocol_id.vest_with_flow      = 1;
protocol_id.visual_flow         = 2;
protocol_id.vest_darkness       = 3;

trial_order = [ones(1, n_trials); 2*ones(1, n_trials); 3*ones(1, n_trials)];

for i = 1 : n_trials
    I = randperm(3);
    trial_order(:, i) = trial_order(I, i);
end

% Step 2: Create the fnames matrix (size: num_speed_profiles x n_trials)
fnames_matrix = cell(num_speed_profiles, n_trials);

% Randomly shuffle the filenames for each row (instead of each column)
for i = 1 : n_trials
    fnames_matrix(:, i) = track_fnames(randperm(num_speed_profiles));
end

% Initialize an empty array to hold the reorganized filenames
reorganized_fnames = {};

% Number of protocol IDs (3)
num_protocols = numel(fieldnames(protocol_id));

% Loop through each row (speed profile)
for row = 1 : num_speed_profiles
    % Loop through each column (trial)
    for col = 1 : n_trials
        % Repeat the filename in fname_matrix(row, col) for 3 times
        reorganized_fnames = [reorganized_fnames; repmat(fnames_matrix(row, col), num_protocols, 1)];
    end
end

% Convert the reorganized_fnames into a cell array if it's not already
reorganized_fnames = reorganized_fnames(:); % ensures it's a column vector

trial_order = trial_order(:);

% Repeat the trial_order sequence for each speed profile
trial_order = repmat(trial_order, num_speed_profiles, 1);

% create full path to file
fnames = cellfun(@(x)(fullfile(data_dir, x)), reorganized_fnames, 'uniformoutput', false);

save('passive_protocol_sequence_motion_clouds.mat', 'fnames', 'protocol_id', 'trial_order');
