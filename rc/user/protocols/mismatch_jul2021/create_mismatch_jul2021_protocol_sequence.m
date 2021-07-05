% create mismatch protocol parameters for July 2021 mismatch experiments

% reset random number generator
rng(1);

% parameters
fname = 'mismatch_jul2021_protocol_sequence.mat';

n_trials = 20;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_jitter       = 300;

% label the protocols
prot.rvt_mismatch_up    = 1;
prot.rv_mismatch_up     = 2;
prot.r_only             = 3;
prot.t_only_r_replay    = 4;


%% protocol order
order = nan(4, n_trials);
for i = 1 : n_trials
    
     this_batch_order = randperm(4);
     
     % always ensure that the replay occurs after the trial to replay
     idx_original = find(this_batch_order == prot.r_only);
     idx_replay = find(this_batch_order == prot.t_only_r_replay);
     
     if idx_replay < idx_original
         this_batch_order([idx_original, idx_replay]) = ...
             this_batch_order([idx_replay, idx_original]);
     end
     
     order(:, i) = this_batch_order;
end
order = order(:);


%% positions
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% the switch position will be half-way down the track minus some
% 'switch_jitter' distance
switch_pos = (config.stage.start_pos + config.stage.forward_limit)/2;
switch_pos = switch_pos + switch_jitter * rand(length(order), 1);

% set the trials without any mismatch to nan
switch_pos(order == prot.r_only | order == prot.t_only_r_replay) = nan;

%% save
save(fname, 'order', 'prot', 'config', 'switch_pos');
