function [trial_order, protocol_id] = create_pseudorandom_sequence_seven_way_motion_clouds()
% Creates seven_way_sequence_motion_clouds.mat for
% seven_way_protocol_motion_clouds.m
%
% trial_order is a 7 x n_batches matrix. Each column is a batch containing
% conditions 1, 2, 3, 5, 7, 8 and 9 once each, in pseudorandom order with
% the rule that condition 1 (locovest) appears before conditions 3, 5 and 7,
% which replay the locovest trial of the same batch.
%
% Each run creates a new pseudorandom sequence and overwrites
% seven_way_sequence_motion_clouds.mat.

n_batches = 8;

% list of protocols
protocol_id.locovest                        = 1;
protocol_id.loco                            = 2;
protocol_id.vest_replay_locovest            = 3;
protocol_id.vest_replay_loco                = 4;    % not used
protocol_id.replay_only_locovest            = 5;
protocol_id.replay_only_loco                = 6;    % not used
protocol_id.vest_replay_locovest_vis_static = 7;
protocol_id.loco_vis_static                 = 8;
protocol_id.locovest_vis_static             = 9;

% conditions presented in every batch
batch_conditions = [protocol_id.locovest, ...
                    protocol_id.loco, ...
                    protocol_id.vest_replay_locovest, ...
                    protocol_id.replay_only_locovest, ...
                    protocol_id.vest_replay_locovest_vis_static, ...
                    protocol_id.loco_vis_static, ...
                    protocol_id.locovest_vis_static];

% conditions which replay the locovest trial of the same batch
replays_of_locovest = [protocol_id.vest_replay_locovest, ...
                       protocol_id.replay_only_locovest, ...
                       protocol_id.vest_replay_locovest_vis_static];

n_conditions = length(batch_conditions);

% seed the random number generator from the clock, so every run gives a
% different sequence
rng('shuffle');

trial_order = nan(n_conditions, n_batches);

for i = 1 : n_batches

    % draw random orderings until condition 1 comes before all its replays
    valid = false;
    while ~valid
        perm = batch_conditions(randperm(n_conditions));
        pos_locovest = find(perm == protocol_id.locovest);
        pos_replays = arrayfun(@(c) find(perm == c), replays_of_locovest);
        valid = all(pos_replays > pos_locovest);
    end

    trial_order(:, i) = perm;
end

% save next to this file
save_dir = fileparts(mfilename('fullpath'));
save(fullfile(save_dir, 'seven_way_sequence_motion_clouds.mat'), 'trial_order', 'protocol_id');
