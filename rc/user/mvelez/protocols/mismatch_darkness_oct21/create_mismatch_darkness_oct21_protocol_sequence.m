% Create mismatch protocol parameters for October 2021 experiments
%   mice will perform 15 trials each of 3 conditions:
%       R - running in darkness without translation
%       T - translation in darkness of the last R trial
%       RT_gain_up - running with translation in darkness with a 'slip'
%                     event


% reset random number generator
rng(1);

% parameters
fname = 'mismatch_darkness_oct21_protocol_sequence.mat';

n_trials            = 15;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_jitter       = 300;

% label the protocols
prot.r_only              = 1;
prot.t_only_r_replay     = 2;
prot.rt_gain_up        = 3;

n_protocols              = 3;

%% protocol order
order = nan(n_protocols, n_trials);
for i = 1 : n_trials
    
    % create an initial order for the batch
    this_batch_order = randperm(n_protocols);
    
    % always ensure that the replay occurs after the trial to replay
    idx_original = find(this_batch_order == prot.r_only);
    idx_replay = find(this_batch_order == prot.t_only_r_replay);
    
    % swap them if replay comes before original
    if idx_replay < idx_original
        this_batch_order([idx_original, idx_replay]) = ...
            this_batch_order([idx_replay, idx_original]);
    end
     
    order(:, i) = this_batch_order;
end

% vectorize
order = order(:);


%% positions
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% the switch position will be half-way down the track give or take
% 'switch_jitter'
switch_pos = (config.stage.start_pos + config.stage.forward_limit)/2;
switch_pos = switch_pos + switch_jitter * rand(length(order), 1);

% only keep switch position info for rt_mismatch_up trials
switch_pos(order == prot.r_only | order == prot.t_only_r_replay) = nan;


%% save
save(fname, 'order', 'prot', 'config', 'switch_pos');
