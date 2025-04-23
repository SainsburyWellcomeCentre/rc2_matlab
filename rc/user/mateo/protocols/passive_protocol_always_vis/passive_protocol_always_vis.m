function seq = passive_protocol_always_vis(ctl)

load('passive_protocol_sequence.mat', 'trial_order', 'protocol_id', 'fnames');
% "trial_order" is a 3xN matrix of protocol indices. Each column is a batch
% of trials specifying a particular order (1-3 in some order that makes sense).
% "protocol_id" is a structure which relates the numbers in "trial_order"
% to the protocol by name:
%       vest_with_flow
%       vest_darkness (in fact, Tvs)
%       visual_flow


% positions along stage
reward_position     = 250;
distance            = 1200;
back_distance       = 5;

% config parameters to pass to the protocols
config.stage.start_pos      = reward_position + distance;
config.stage.back_limit     = config.stage.start_pos + back_distance;
config.stage.forward_limit  = reward_position;


% create the protocol sequence
seq = ProtocolSequence(ctl);

% we will randomize the rewards
seq.randomize_reward = true;


% insert all the trials
for i = 1 : length(trial_order)
    
    if trial_order(i) == protocol_id.vest_with_flow
        
        % setup the locovest replay protocol
        vest = StageOnly(ctl, config);
        
        % mouse must initiate trial
        vest.initiate_trial = false;
        
        % increase start dwell time slightly
        vest.start_dwell_time = 4;
        
        vest.wave_fname = fnames{i};
        
        % enable vis stim
        vest.enable_vis_stim = true;
        vest.enable_vis_stim_gain = true;
        
        % add protocol to the sequence
        seq.add(vest);
        
    elseif trial_order(i) == protocol_id.vest_darkness % TODO change name to appropriate protocol ID
        
        % setup the locovest replay protocol
        vest = StageOnly(ctl, config);
        
        % mouse must initiate trial
        vest.initiate_trial = false;
        
        % increase start dwell time slightly
        vest.start_dwell_time = 4;
        
        vest.wave_fname = fnames{i};
        
        % enable vis stim
        vest.enable_vis_stim = true;
        vest.enable_vis_stim_gain = false;
        
        % add protocol to the sequence
        seq.add(vest);
        
    elseif trial_order(i) == protocol_id.visual_flow
        
        % setup the locovest protocol
        replay = ReplayOnly(ctl, config);
        
        % mouse must initiate trial
        replay.initiate_trial = false;
        
        % increase start dwell time slightly
        replay.start_dwell_time = 4;
        
        replay.wave_fname = fnames{i};
        
        % enable vis stim
        replay.enable_vis_stim = true;
        
        % add protocol to the sequence
        seq.add(replay);
        
    end
end
