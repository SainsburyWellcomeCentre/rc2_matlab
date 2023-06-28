function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    nTrials = 4;
    gain_seq = {[0, 0], [0, 1], [1, 1], [1, 0]};
    
    assert(nTrials == length(gain_seq), 'Warning: number of trials does not match the number of gain factors');
    
    for i = 1 : nTrials
       trial = Shelter(ctl, config);
       trial.gain_triggers = gain_seq{i};
       trial.timeout_seconds = config.timeout.timeout_seconds;
       seq.add(trial); 
    end
end

