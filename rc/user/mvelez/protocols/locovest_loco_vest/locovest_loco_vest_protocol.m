function seq = locovest_loco_vest_protocol(ctl)


load('protocol_sequence.mat', 'order', 'prot');

% saved waveforms
waveforms_location = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\waveforms';
waveform_basename = 'CA_529_2_trn11_001_single_trial_';

reward_position     = 250;
distance            = 1200;
back_distance       = 5;

config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

% iterate over saved waveforms
current_saved_waveform = 0;


% it will loop n_loops number of times
for i = 1 : length(order)
    if order(i) == prot.locovest
        
        % setup the locovest protocol
        locovest = Coupled(ctl, config);
        
        % we will log this trial
        locovest.log_trial = true;
        
        % setup filenames at start
        fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
            ctl.saver.prefix, ...
            ctl.saver.suffix, ...
            ctl.saver.index, ...
            prot.locovest, ...
            i);
        
        locovest.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % we are doing this in the darkness
        locovest.enable_vis_stim = false;
        
        seq.add(locovest);
        
        last_fname = locovest.log_fname;
        
    elseif order(i) == prot.loco
        
        % setup the locovest protocol
        loco = EncoderOnly(ctl, config);
        
        % we will log this trial
        loco.log_trial = true;
        
        % setup filenames at start
        fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
            ctl.saver.prefix, ...
            ctl.saver.suffix, ...
            ctl.saver.index, ...
            prot.loco, ...
            i);
        
        loco.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % integrate with the PC
        loco.integrate_using = 'pc';
        
        % we are doing this in the darkness
        loco.enable_vis_stim = false;
        
        % add protocol to the sequence
        seq.add(loco);
        
        last_fname = loco.log_fname;
        
        
    elseif order(i) == prot.vest
        
        % setup the locovest replay protocol
        vest_replay = StageOnly(ctl, config);
        vest_replay.enable_vis_stim = false;
        vest_replay.initiate_trial = true;
        vest_replay.start_dwell_time = 6;
        vest_replay.wave_fname = last_fname;
        
        seq.add(vest_replay);
        
        
    elseif order(i) == prot.vest_from_bank
        
        current_saved_waveform = current_saved_waveform + 1;
        
        vest_saved = StageOnly(ctl, config);
        vest_saved.enable_vis_stim = false;
        vest_saved.initiate_trial = true;
        vest_saved.start_dwell_time = 6;
        vest_saved.wave_fname = fullfile(waveforms_location, sprintf('%s%03i.bin', waveform_basename, current_saved_waveform));
        
        seq.add(vest_saved);
    end
end