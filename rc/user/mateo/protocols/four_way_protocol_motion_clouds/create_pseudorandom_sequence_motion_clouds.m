function [trial_order, protocol_id] = create_pseudorandom_sequence_motion_clouds()

n_batches = 12;

% list of protocols
protocol_id.locovest                = 1;
protocol_id.loco                    = 2;
protocol_id.vest_replay_locovest    = 3;
protocol_id.vest_replay_loco        = 4;
protocol_id.replay_only_locovest    = 5;
protocol_id.replay_only_loco        = 6;


% store the order in batches (4 trials per batch)
trial_order = nan(4, n_batches);

for i = 1 : n_batches
    
    if mod(i, 2) == 1
        % odd batches: conditions 1, 2, 3 (vest_replay_locovest), 5 (replay_only_locovest)
        batch_conditions = [1, 2, 3, 5];
    else
        % even batches: conditions 1, 2, 4 (vest_replay_loco), 6 (replay_only_loco)
        batch_conditions = [1, 2, 4, 6];
    end
    
    % randomly shuffle the 4 conditions within this batch
    trial_order(:, i) = batch_conditions(randperm(4));
end
