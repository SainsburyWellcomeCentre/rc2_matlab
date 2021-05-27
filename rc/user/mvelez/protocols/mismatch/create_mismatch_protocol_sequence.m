% create mismatch protocol parameters

% reset random number generator
rng(1);

% parameters
fname = 'mismatch_protocol_sequence_test.mat';

n_trials = 30;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_jitter       = 300;

% label the protocols
prot.locovest2loco = 1;
prot.loco2locovest = 2;

%% protocol order
order = [1; 2];
for i = 2 : n_trials
    a = randi(2);
    order(1, i) = a;
    order(2, i) = mod(a, 2)+1;
end
order = order(:);

%% don't start with loco2locovest
if order(1) == prot.loco2locovest
    % find all trials with locovest2loco
    idx = find(order == prot.locovest2loco);
    % replace the first with a loco2locovest
    order(idx(1)) = prot.loco2locovest;
    % replace the first with a locovest2loco
    order(1) = prot.locovest2loco;
end


%% positions
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% the switch position will be half-way down the track give or take
% 'switch_jitter'
switch_pos = (config.stage.start_pos + config.stage.forward_limit)/2;
switch_pos = switch_pos - switch_jitter + 2*switch_jitter*rand(length(order), 1);

%% save
save(fname, 'order', 'prot', 'config', 'switch_pos');
