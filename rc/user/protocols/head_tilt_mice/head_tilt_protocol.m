function seq = head_tilt_protocol(ctl)

load('head_tilt_protocol_sequence.mat', 'trial_order', 'protocol_id');
% "trial_order" is a 3xN matrix of protocol indices. Each column is a batch
% of trials specifying a particular order (1-4 in some order that makes sense).
% "protocol_id" is a structure which relates the numbers in "trial_order"
% to the protocol by name:
%       vest_with_flow
%       vest_darkness
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
for i = 1 : size(trial_order, 2)
    
    for j  = 1 : size(trial_order, 1)
        
        if trial_order(j, i) == protocol_id.vest_with_flow
            
            % setup the locovest replay protocol
            vest = StageOnly(ctl, config);
            
            % mouse must initiate trial
            vest.initiate_trial = true;
            
            % increase start dwell time slightly
            vest.start_dwell_time = 6;
            
            % same filename as loco
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.loco, ...
                i);
            
            vest.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % enable vis stim
            vest.enable_vis_stim = true;
            
            % add protocol to the sequence
            seq.add(vest);
            
        elseif trial_order(j, i) == protocol_id.vest_darkness
            
            % setup the locovest replay protocol
            vest = StageOnly(ctl, config);
            
            % mouse must initiate trial
            vest.initiate_trial = true;
            
            % increase start dwell time slightly
            vest.start_dwell_time = 6;
            
            % same filename as loco
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.loco, ...
                i);
            
            vest.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % enable vis stim
            vest.enable_vis_stim = false;
            
            % add protocol to the sequence
            seq.add(vest);
            
            
        elseif trial_order(j, i) == protocol_id.visual_flow
            
            % setup the locovest protocol
            replay = ReplayOnly(ctl, config);
            
            % mouse must initiate trial
            replay.initiate_trial = true;
            
            % increase start dwell time slightly
            replay.start_dwell_time = 6;
            
            % same filename as locovest
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.locovest, ...
                i);
            
            replay.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % add protocol to the sequence
            seq.add(replay);
            
        end
    end
end
