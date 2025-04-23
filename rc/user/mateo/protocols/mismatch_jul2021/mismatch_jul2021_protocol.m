function seq = mismatch_jul2021_protocol(ctl)

fname = 'mismatch_jul2021_protocol_sequence.mat';

load(fname, 'prot', 'order', 'config', 'switch_pos');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

mismatch_duration = 0.2;

%disp(order);

for i = 1 : length(order)

    if order(i) == prot.rvt_mismatch_up
        
        % R+V+T trial with gain up period
        rvt_up = CoupledMismatch(ctl, config);
        rvt_up.switch_pos = switch_pos(i);
        rvt_up.gain_direction = 'up';
        rvt_up.mismatch_duration = mismatch_duration;
        seq.add(rvt_up);
        
    elseif order(i) == prot.rv_mismatch_up
        
        % R+V trial with gain up period
        rv_up = EncoderOnlyMismatch(ctl, config);
        rv_up.switch_pos = switch_pos(i);
        rv_up.gain_direction = 'up';
        rv_up.mismatch_duration = mismatch_duration;
        seq.add(rv_up);
        
    elseif order(i) == prot.r_only
        
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
    end
end
