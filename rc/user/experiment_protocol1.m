function seq = experiment_protocol1(ctl)


load('protocol_sequence.mat', 'order', 'prot');

% saved waveforms
waveforms_location = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\waveforms';
waveform_basename = '201911141434_28_001_single_trial_';
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

% setup the loco only protocol
loco = EncoderOnly(ctl, config);
loco.log_trial = true;
loco.integrate_using = 'pc';

% setup the vest only protocol
vest_replay = StageOnly(ctl, config);
vest_replay.follow_previous_protocol = true;

% 
for i = 1 : n_saved_waveforms
    fname = fullfile(waveforms_location, sprintf('%s%03i.bin', waveform_basename, i));
    vest_saved(i) = StageOnly(ctl, config, fname);
end


% setup the protocol sequence
seq = ProtocolSequence(ctl);

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