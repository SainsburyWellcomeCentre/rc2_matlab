function [trial_order, protocol_id, file_no] = create_head_tilt_protocol_sequence()
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
%   rng(1) gives too many 3's at the beginning
rng(2)

% number of velocity profiles
n_batches = 20;

% list of protocols
protocol_id.vest_with_flow      = 1;
protocol_id.vest_darkness       = 2;
protocol_id.visual_flow         = 3;

% 
trial_order_ = repmat(1:3, n_batches, 1);
file_no_ = [randperm(n_batches)', randperm(n_batches)', randperm(n_batches)'];


trial_order = nan(3, n_batches);
file_no = nan(3, n_batches);

for i = 1 : n_batches
    
    I = randperm(3);
    trial_order(:, i) = I;
    file_no(:, i) = file_no_(i, I);
    
end
