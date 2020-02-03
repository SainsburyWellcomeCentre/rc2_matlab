function seq = locovest_loco_vest_protocol(ctl)


load('protocol_sequence.mat', 'order', 'prot');

% saved waveforms
waveforms_location = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\waveforms';
waveform_basename = 'CA_529_2_trn11_001_single_trial_';
n_saved_waveforms = 8;

reward_position     = 250;
distance            = 1200;
back_distance       = 5;

config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% setup the locovest protocol
locovest = Coupled(ctl, config);
locovest.log_trial = true;
locovest.enable_vis_stim = false;

% setup the loco only protocol
loco = EncoderOnly(ctl, config);
loco.log_trial = true;
loco.integrate_using = 'pc';
loco.enable_vis_stim = false;

% setup the vest only protocol
vest_replay = StageOnly(ctl, config);
vest_replay.follow_previous_protocol = true;
vest_replay.enable_vis_stim = false;
vest_replay.initiate_trial = true;

% 
for i = 1 : n_saved_waveforms
    fname = fullfile(waveforms_location, sprintf('%s%03i.bin', waveform_basename, i));
    vest_saved(i) = StageOnly(ctl, config, fname);
    vest_saved(i).enable_vis_stim = false;
    vest_saved(i).initiate_trial = true;
end


% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

% iterate over saved waveforms
current_saved_waveform = 0;

% it will loop n_loops number of times
for i = 1 : length(order)
    if order(i) == prot.locovest
        seq.add(locovest);
    elseif order(i) == prot.loco
        seq.add(loco);
    elseif order(i) == prot.vest
        seq.add(vest_replay);
    elseif order(i) == prot.vest_from_bank
        current_saved_waveform = current_saved_waveform + 1;
        seq.add(vest_saved(current_saved_waveform));
    end
end