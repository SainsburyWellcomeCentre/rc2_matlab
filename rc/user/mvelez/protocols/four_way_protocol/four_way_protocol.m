function seq = four_way_protocol(ctl)

% load the order of trials
load('four_way_sequence.mat', 'trial_order', 'protocol_id');
% "trial_order" is a 6xN matrix of protocol indices. Each column is a batch
% of trials specifying a particular order (1-6 in some order that makes sense).
% "protocol_id" is a structure which relates the numbers in "trial_order"
% to the protocol by name:
%       locovest
%       loco
%       vest_replay_locovest
%       vest_replay_loco
%       replay_only_locovest
%       replay_only_loco


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
        
        if trial_order(j, i) == protocol_id.locovest
            
            % setup the locovest protocol
            locovest = Coupled(ctl, config);
            
            % we will log this trial
            locovest.log_trial = true;
            
            % setup filenames at start
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.locovest, ...
                i);
            
            locovest.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % we will true
            locovest.enable_vis_stim = true;
            
            % add protocol to the sequence
            seq.add(locovest);
            
        elseif trial_order(j, i) == protocol_id.loco
            
            % setup the locovest protocol
            loco = EncoderOnly(ctl, config);
            
            % we will log this trial
            loco.log_trial = true;
            
            %
            loco.integrate_using = 'pc';
            
            % setup filenames at start
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.loco, ...
                i);
            
            loco.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % we will true
            loco.enable_vis_stim = true;
            
            % add protocol to the sequence
            seq.add(loco);
            
            
        elseif trial_order(j, i) == protocol_id.vest_replay_locovest
            
            % setup the locovest protocol
            vest = StageOnly(ctl, config);
            
            % mouse must initiate trial
            vest.initiate_trial = true;
            
            % increase start dwell time slightly
            vest.start_dwell_time = 6;
            
            % same filename as locovest
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.locovest, ...
                i);
            
            vest.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % add protocol to the sequence
            seq.add(vest);
            
            
        elseif trial_order(j, i) == protocol_id.vest_replay_loco
            
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
            
            % add protocol to the sequence
            seq.add(vest);
            
            
        elseif trial_order(j, i) == protocol_id.replay_only_locovest
            
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
            
        elseif trial_order(j, i) == protocol_id.replay_only_loco
            
            % setup the locovest protocol
            replay = ReplayOnly(ctl, config);
            
            % mouse must initiate trial
            replay.initiate_trial = true;
            
            % increase start dwell time slightly
            replay.start_dwell_time = 6;
            
            % same filename as loco
            fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
                ctl.saver.prefix, ...
                ctl.saver.suffix, ...
                ctl.saver.index, ...
                protocol_id.loco, ...
                i);
            
            replay.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
            
            % add protocol to the sequence
            seq.add(replay);
            
        end
    end
end
