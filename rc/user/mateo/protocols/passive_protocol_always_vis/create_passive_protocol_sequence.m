function [trial_order, fnames, protocol_id] = create_passive_protocol_sequence()
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

% data location
data_dir = fullfile(pwd, 'passive_waveforms_250423');

track_fnames = dir(fullfile(data_dir, '*.bin'));
track_fnames = {track_fnames(:).name};


% list of protocols
protocol_id.vest_with_flow      = 1;
protocol_id.visual_flow         = 2;
protocol_id.vest_darkness       = 3;

% number of trials in each protocol
n_trials = length(track_fnames);

trial_order = [ones(1, n_trials); 2*ones(1, n_trials); 3*ones(1, n_trials)];
file_id = nan(3, n_trials);

for i = 1 : 3    
    file_id(i, :) = randperm(n_trials);    
end


for i = 1 : n_trials
    I = randperm(3);
    trial_order(:, i) = trial_order(I, i);
    file_id(:, i) = file_id(I, i);
end

trial_order = trial_order(:);
fnames = track_fnames(file_id(:))';

% create full path to file
fnames = cellfun(@(x)(fullfile(data_dir, x)), fnames, 'uniformoutput', false);

save('passive_protocol_sequence.mat', 'fnames', 'protocol_id', 'trial_order');
