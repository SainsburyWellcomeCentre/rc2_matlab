function seq = mismatch_jul2021_mock_protocol(ctl)
%% protocol sequence for mock experiments in preparation for mismatch_jul2021
% These protocols are in preparation for the mismatch experiments. The
% sequence is the same as mismatch_jul2021, but there is no mismatch event
% in the RVT or RV trials.

% load the same protocol
fname = 'mismatch_jul2021_protocol_sequence.mat';

load(fname, 'prot', 'order', 'config');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;


for i = 1 : length(order)
    
    % the protocols are called 'rvt_mismatch_up', but we will not apply the
    % gain up.
    if order(i) == prot.rvt_mismatch_up
        
        % R+V+T trial WITHOUT gain up period
        rvt_up = Coupled(ctl, config);
        seq.add(rvt_up);
        
    elseif order(i) == prot.rv_mismatch_up
        
        % R+V trial WITHOUT gain up period
        rv_up = EncoderOnly(ctl, config);
        seq.add(rv_up);
        
    elseif order(i) == prot.r_only
        
        % R trial
        r_only = EncoderOnly(ctl, config);
        
        % use the same script as the mismatch trials
        %   (we just don't send the trigger to change gain)
        r_only.direction = 'forward_only';
        
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
        t_only_r_replay.direction = 'forward_only';
        
        % mouse must initiate trial
        t_only_r_replay.initiate_trial = true;
        
        % increase start dwell time slightly
        t_only_r_replay.start_dwell_time = 6;
        
        % fname_ still exists from previous loop
        t_only_r_replay.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % in darkness
        t_only_r_replay.enable_vis_stim = false;
        
        % add protocol to the sequence
        seq.add(t_only_r_replay);
    end
end
