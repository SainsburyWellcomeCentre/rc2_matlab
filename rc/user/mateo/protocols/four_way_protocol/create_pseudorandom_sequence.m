function [trial_order, protocol_id] = create_pseudorandom_sequence()

n_batches = 16;

% list of protocols
protocol_id.locovest                = 1;
protocol_id.loco                    = 2;
protocol_id.vest_replay_locovest    = 3;
protocol_id.vest_replay_loco        = 4;
protocol_id.replay_only_locovest    = 5;
protocol_id.replay_only_loco        = 6;


% store the order in batches
trial_order = nan(6, n_batches);

for i = 1 : n_batches
    
    % first can either be locovest or loco
    trial_order(1, i) = randi(2);
    
    % choose next protocol id based on previous
    trial_order(2, i) = choose_next_protocol(trial_order(:, i));
    trial_order(3, i) = choose_next_protocol(trial_order(:, i));
    
    % if 1 or 2 don't appear then they need to at this point
    if ~ismember(1, trial_order(:, i))
        trial_order(4, i) = 1;
    elseif ~ismember(2, trial_order(:, i))
        trial_order(4, i) = 2;
    else
        trial_order(4, i) = choose_next_protocol(trial_order(:, i));
    end
    
    % choose next protocol id based on previous
    trial_order(5, i) = choose_next_protocol(trial_order(:, i));
    trial_order(6, i) = choose_next_protocol(trial_order(:, i));
end




function prot_id = choose_next_protocol(order)

% get the list of ids which are acceptable given the previous ids
protocol_options = get_protocol_options(order);

% choose one of them
rand_idx = randi(length(protocol_options));
prot_id = protocol_options(rand_idx);



function ops = get_protocol_options(order)

ops = [1, 2];

% if locovest in there, we can have vest_replay_locovest or
% replay_only_locovest
if ismember(1, order)
    ops = [ops, 3, 5];
end

% if loco in there, we can have vest_replay_loco or
% replay_only_loco
if ismember(2, order)
    ops = [ops, 4, 6];
end

% remove those ids already existing in the protocol order
ops(ismember(ops, order)) = [];


