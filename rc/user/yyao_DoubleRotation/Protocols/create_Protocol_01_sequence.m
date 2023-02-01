function [trial_order, fnames, protocol_id] = create_passive_protocol_sequence()
% Create visual stimuli trial sequence for the mice. This consists of:
%
%   1. s_plus (forward)
%   2. s_minusL (forward with left rotation)
%   3. s_minusR (forward with right rotation)
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

% list of protocols
protocol_id.s_plus          = 1;
protocol_id.s_minusL        = 2;
protocol_id.s_minusR        = 3;

% number of trials in each block
n_s_plus_trials     = 0;
n_s_minusL_trials   = 2;
n_s_minusR_trials   = 1;

n_blocks = 10;

% s_isvalid = [logical(n_s_plus_trials),logical(n_s_minusL_trials),logical(n_s_minusR_trials)];

trial_order = [ones(n_s_plus_trials, n_blocks); 2*ones(n_s_minusL_trials, n_blocks); 3*ones(n_s_minusR_trials, n_blocks)];
file_id = nan(sum([n_s_plus_trials,n_s_minusL_trials,n_s_minusR_trials]) , n_blocks);

for i = 1 : sum([n_s_plus_trials,n_s_minusL_trials,n_s_minusR_trials])
    file_id(i, :) = randperm(n_blocks);
end


for i = 1 : n_blocks
    I = randperm(sum([n_s_plus_trials,n_s_minusL_trials,n_s_minusR_trials]));
    trial_order(:, i) = trial_order(I, i);
    file_id(:, i) = file_id(I, i);
end

trial_order = trial_order(:);
fnames = track_fnames(file_id(:))';

% create full path to file
fnames = cellfun(@(x)(fullfile(data_dir, x)), fnames, 'uniformoutput', false);
