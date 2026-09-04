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
        % rules: batch starts with 1 or 2; 3 and 5 must come after 1; 4 and 6 must come after 2
        batch_conditions = [1, 2, 3, 5];
    else
        % even batches: conditions 1, 2, 4 (vest_replay_loco), 6 (replay_only_loco)
        % rules: batch starts with 1 or 2; 4 and 6 must come after 2
        batch_conditions = [1, 2, 4, 6];
    end
    
    % Build a valid random ordering:
    % - position 1 must be condition 1 or 2 (chosen randomly)
    % - conditions dependent on 1 (3, 5) must appear after position of 1
    % - conditions dependent on 2 (4, 6) must appear after position of 2
    valid = false;
    while ~valid
        perm = batch_conditions(randperm(4));
        pos1 = find(perm == 1);
        pos2 = find(perm == 2);
        % rule 1: batch must start with condition 1 or 2
        starts_ok = (perm(1) == 1 || perm(1) == 2);
        % rule 2: conditions 3 and 5 must appear after condition 1
        dep_of_1 = batch_conditions(batch_conditions == 3 | batch_conditions == 5);
        after1_ok = all(arrayfun(@(c) find(perm == c) > pos1, dep_of_1));
        % rule 3: conditions 4 and 6 must appear after condition 2
        dep_of_2 = batch_conditions(batch_conditions == 4 | batch_conditions == 6);
        after2_ok = all(arrayfun(@(c) find(perm == c) > pos2, dep_of_2));
        valid = starts_ok && after1_ok && after2_ok;
    end
    trial_order(:, i) = perm;
end
