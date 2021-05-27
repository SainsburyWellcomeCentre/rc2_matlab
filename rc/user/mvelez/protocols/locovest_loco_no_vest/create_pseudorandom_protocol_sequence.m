% create mismatch protocol parameters

% reset random number generator
rng(1);

% parameters
fname = 'locovest_loco_protocol_sequence.mat';

n_trials = 30;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;

% label the protocols
prot.locovest       = 1;
prot.loco           = 2;

%% protocol order
order = nan(2, n_trials);
for i = 1 : n_trials
    a = randi(2);
    order(1, i) = a;
    order(2, i) = mod(a, 2)+1;
end
order = order(:);


%% positions
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

%% save
save(fname, 'order', 'prot', 'config');
