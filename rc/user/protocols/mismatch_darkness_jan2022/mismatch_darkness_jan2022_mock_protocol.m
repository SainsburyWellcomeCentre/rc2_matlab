function seq = mismatch_darkness_jan2022_mock_protocol(ctl)
%%MISMATCH_DARKNESS_JAN2022_MOCK_PROTOCOL
%
%   SEQUENCE = mismatch_darkness_jan2022_mock_protocol(CTL) returns a protocol
%   sequence in SEQUENCE (of class ProtocolSequence) containing a sequence
%   of trials for the mismatch_darkness_jan2022_mock training day 
%
%   See also: mismatch_darkness_jan2022_protocol

fname = 'mismatch_darkness_jan2022_protocol_sequence.mat';

load(fname, 'prot', 'order', 'config');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

% it will loop n_loops number of times
for i = 1 : length(order)
    
    if order(i) == prot.rt_mismatch_up
        
        % R+T without gain up
        rt                   = Coupled(ctl, config);
        rt.direction         = 'forward_only_variable_gain';
        rt.enable_vis_stim   = false;
        
        % setup filenames at start
        fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
            ctl.saver.prefix, ...
            ctl.saver.suffix, ...
            ctl.saver.index, ...
            prot.rt_mismatch_up, ...
            i);
        
        rt.log_trial = true;
        rt.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        seq.add(rt);
        
    elseif order(i) == prot.t_only
        
        t_only = StageOnly(ctl, config);
        
        % use the same script as the mismatch trials
        %   (we just don't send the trigger to change gain)
        t_only.direction = 'forward_only_variable_gain';
        
        t_only.initiate_trial = true;
        
        % increase start dwell time slightly
        t_only.start_dwell_time = 6;
        
        % fname_ still exists from previous loop
        t_only.wave_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);
        
        % we will present vis stim
        t_only.enable_vis_stim = false;
        
        seq.add(t_only);
    end
end
