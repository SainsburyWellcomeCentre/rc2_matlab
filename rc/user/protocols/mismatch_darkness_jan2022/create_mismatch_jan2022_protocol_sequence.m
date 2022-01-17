% create mismatch protocol parameters for experiments in Jan 2022

% Creates a protocol sequence for the mismatch_darkness_jan2022 experiments
% examining mismatch responses (gain increase between treadmill velocity
% and stage velocity) in various cortical and subcortical regions, all
% taking place in darkness. CTL is the main setup controller object (class
% Controller or RC2Controller).

% reset random number generator
rng(1);

% parameters
fname = 'mismatch_darkness_jan2022_protocol_sequence.mat';

n_trials            = 10;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_jitter       = 300;

% label the protocols
prot.rt_mismatch_up = 1;
prot.t_only = 2;

%% protocol order
% first batch has specified order (only one trial type)
order               = [ones(1, n_trials); 2*ones(1, n_trials)];
order               = order(:);

%% positions
config.stage.start_pos      = reward_position + distance;
config.stage.back_limit     = config.stage.start_pos + back_distance;
config.stage.forward_limit  = reward_position;

% the switch position will be half-way down the track give or take
% 'switch_jitter'
switch_pos      = (config.stage.start_pos + config.stage.forward_limit)/2;
switch_pos      = switch_pos + switch_jitter * rand(length(order), 1);
switch_pos(order == prot.t_only) = nan;

%% save
save(fname, 'order', 'prot', 'config', 'switch_pos');
