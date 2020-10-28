% create mismatch protocol parameters

% reset random number generator
rng(1);

% parameters
fname = 'mismatch_nov2020_protocol_sequence.mat';

n_trials = 20;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_jitter       = 300;

% label the protocols
prot.mt_mismatch_down   = 1;
prot.mt_mismatch_up     = 2;
prot.m_mismatch_down    = 3;
prot.m_mismatch_up      = 4;

%% protocol order
order = [];
for i = 1 : n_trials
    order(:, i) = randi(4);
end
order = order(:);

%% positions
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% the switch position will be half-way down the track give or take
% 'switch_jitter'
switch_pos = (config.stage.start_pos + config.stage.forward_limit)/2;
switch_pos = switch_pos - switch_jitter + 2*switch_jitter * rand(length(order), 1);

%% save
save(fname, 'order', 'prot', 'config', 'switch_pos');
