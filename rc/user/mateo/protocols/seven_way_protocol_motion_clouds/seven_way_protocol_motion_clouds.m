function seq = seven_way_protocol_motion_clouds(ctl)

% load the order of trials
load('seven_way_sequence_motion_clouds.mat', 'trial_order', 'protocol_id');
% "trial_order" is an MxN matrix of protocol indices. Each column is a batch
% of trials specifying a particular order. The trials in a column are
% presented in order from top to bottom.
%
% "protocol_id" is a structure which relates the numbers in "trial_order"
% to the protocol by name:
%   1   locovest                            running + translation, visual flow
%   2   loco                                running, no translation, visual flow
%   3   vest_replay_locovest                translation replay of locovest, visual flow
%   4   vest_replay_loco                    (not used, kept as an option)
%   5   replay_only_locovest                visual flow replay of locovest, no translation
%   6   replay_only_loco                    (not used, kept as an option)
%   7   vest_replay_locovest_vis_static     translation replay of locovest, visual static
%   8   loco_vis_static                     running, no translation, visual static
%   9   locovest_vis_static                 running + translation, visual static
%
% The seven conditions in use are 1, 2, 3, 5, 7, 8, 9.
%
% NOTE: replay conditions (3, 4, 5, 6, 7) replay the trial logged by the
% locovest (1) or loco (2) trial *of the same batch* (column). Each batch
% containing a replay must therefore contain the corresponding locovest/loco
% trial earlier in the same column.

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


% filename of the single trial log for protocol "prot_id" in batch "batch_i"
trial_fname = @(prot_id, batch_i) fullfile(ctl.saver.save_to, ctl.saver.prefix, ...
    sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
        ctl.saver.prefix, ...
        ctl.saver.suffix, ...
        ctl.saver.index, ...
        prot_id, ...
        batch_i));


% insert all the trials
for i = 1 : size(trial_order, 2)

    for j  = 1 : size(trial_order, 1)

        if trial_order(j, i) == protocol_id.locovest

            % setup the locovest protocol
            locovest = Coupled(ctl, config);

            % we will log this trial
            locovest.log_trial = true;
            locovest.log_fname = trial_fname(protocol_id.locovest, i);

            % visual flow coupled to motion
            locovest.enable_vis_stim = true;
            locovest.enable_vis_stim_gain = true;

            % add protocol to the sequence
            seq.add(locovest);

        elseif trial_order(j, i) == protocol_id.loco

            % setup the loco protocol
            loco = EncoderOnly(ctl, config);

            % we will log this trial
            loco.log_trial = true;
            loco.log_fname = trial_fname(protocol_id.loco, i);

            loco.integrate_using = 'pc';

            % visual flow coupled to motion
            loco.enable_vis_stim = true;
            loco.enable_vis_stim_gain = true;

            % add protocol to the sequence
            seq.add(loco);

        elseif trial_order(j, i) == protocol_id.vest_replay_locovest

            % setup the vestibular replay protocol
            vest = StageOnly(ctl, config);

            % mouse must initiate trial
            vest.initiate_trial = true;

            % increase start dwell time slightly
            vest.start_dwell_time = 6;

            % replay the locovest trial of this batch
            vest.wave_fname = trial_fname(protocol_id.locovest, i);

            % visual flow coupled to motion
            vest.enable_vis_stim = true;
            vest.enable_vis_stim_gain = true;

            % add protocol to the sequence
            seq.add(vest);

        elseif trial_order(j, i) == protocol_id.vest_replay_loco

            % setup the vestibular replay protocol
            vest = StageOnly(ctl, config);

            % mouse must initiate trial
            vest.initiate_trial = true;

            % increase start dwell time slightly
            vest.start_dwell_time = 6;

            % replay the loco trial of this batch
            vest.wave_fname = trial_fname(protocol_id.loco, i);

            % visual flow coupled to motion
            vest.enable_vis_stim = true;
            vest.enable_vis_stim_gain = true;

            % add protocol to the sequence
            seq.add(vest);

        elseif trial_order(j, i) == protocol_id.replay_only_locovest

            % setup the visual replay protocol
            replay = ReplayOnly(ctl, config);

            % mouse must initiate trial
            replay.initiate_trial = true;

            % increase start dwell time slightly
            replay.start_dwell_time = 6;

            % replay the locovest trial of this batch
            replay.wave_fname = trial_fname(protocol_id.locovest, i);

            replay.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(replay);

        elseif trial_order(j, i) == protocol_id.replay_only_loco

            % setup the visual replay protocol
            replay = ReplayOnly(ctl, config);

            % mouse must initiate trial
            replay.initiate_trial = true;

            % increase start dwell time slightly
            replay.start_dwell_time = 6;

            % replay the loco trial of this batch
            replay.wave_fname = trial_fname(protocol_id.loco, i);

            replay.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(replay);

        elseif trial_order(j, i) == protocol_id.vest_replay_locovest_vis_static

            % setup the vestibular replay protocol
            vest = StageOnly(ctl, config);

            % mouse must initiate trial
            vest.initiate_trial = true;

            % increase start dwell time slightly
            vest.start_dwell_time = 6;

            % replay the locovest trial of this batch
            vest.wave_fname = trial_fname(protocol_id.locovest, i);

            % visual stimulus on, but static (gain off)
            vest.enable_vis_stim = true;
            vest.enable_vis_stim_gain = false;

            % add protocol to the sequence
            seq.add(vest);

        elseif trial_order(j, i) == protocol_id.loco_vis_static

            % setup the loco protocol
            loco = EncoderOnly(ctl, config);

            % we will log this trial
            loco.log_trial = true;
            loco.log_fname = trial_fname(protocol_id.loco_vis_static, i);

            loco.integrate_using = 'pc';

            % visual stimulus on, but static (gain off)
            loco.enable_vis_stim = true;
            loco.enable_vis_stim_gain = false;

            % add protocol to the sequence
            seq.add(loco);

        elseif trial_order(j, i) == protocol_id.locovest_vis_static

            % setup the locovest protocol
            locovest = Coupled(ctl, config);

            % we will log this trial
            locovest.log_trial = true;
            locovest.log_fname = trial_fname(protocol_id.locovest_vis_static, i);

            % visual stimulus on, but static (gain off)
            locovest.enable_vis_stim = true;
            locovest.enable_vis_stim_gain = false;

            % add protocol to the sequence
            seq.add(locovest);

        else

            error('seven_way_protocol_motion_clouds: unknown protocol id %i (batch %i, row %i)', ...
                trial_order(j, i), i, j);

        end
    end
end
