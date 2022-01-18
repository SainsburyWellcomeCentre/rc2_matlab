function seq = mismatch_darkness_oct21_protocol(ctl)

% filename to load
fname = 'mismatch_darkness_oct21_protocol_sequence.mat';
load(fname, 'prot', 'order', 'config', 'switch_pos');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

mismatch_duration = 0.2;

% add each protocol to the sequence
for i = 1 : length(order)
    
    if order(i) == prot.r_only
        
        % R trial
        r_only = EncoderOnly(ctl, config);
        
        % use the same script as the mismatch trials
        %   (we just don't send the trigger to change gain)
        r_only.direction = 'forward_only_variable_gain';
        
        % we will log this trial
        r_only.log_trial = true;
        
        % setup filenames at start
        fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
            ctl.saver.prefix, ...
            ctl.saver.suffix, ...
            ctl.saver.index, ...
            prot.r_only, ...
            i);
        
        r_only.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % in darkness
        r_only.enable_vis_stim = false;
        
        % add protocol to the sequence
        seq.add(r_only);
        
    elseif order(i) == prot.t_only_r_replay
        
        % setup the T replay
        t_only_r_replay = StageOnly(ctl, config);
        
        % use the same script as the mismatch trials
        %   (we just don't send the trigger to change gain)
        t_only_r_replay.direction = 'forward_only_variable_gain';
        
        % mouse must initiate trial
        t_only_r_replay.initiate_trial = true;
        
        % increase start dwell time slightly
        t_only_r_replay.start_dwell_time = 6;
        
        % fname_ still exists from previous loop
        t_only_r_replay.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % we will present vis stim
        t_only_r_replay.enable_vis_stim = false;
        
        % add protocol to the sequence
        seq.add(t_only_r_replay);
        
    elseif order(i) == prot.rt_gain_up
        
        % R+T trial with gain up period
        rt_gain_up = CoupledMismatch(ctl, config);
        rt_gain_up.switch_pos = switch_pos(i);
        rt_gain_up.gain_direction = 'up';
        rt_gain_up.mismatch_duration = mismatch_duration;
        rt_gain_up.enable_vis_stim = false;
        
        seq.add(rt_gain_up);
    end
end