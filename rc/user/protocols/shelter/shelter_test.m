function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    nTrials = 5;
    gain_seq = {[1, 1], [0, 1], [1, 1], [1, 0], [0, 0]}; % Defines the gain pins high or low. e.g. [1, 1] is both pins high = default gain. [0, 0] is both bins low = zero gain. [1, 0] is HIGH high = max gain.
    
    assert(nTrials == length(gain_seq), 'Warning: number of trials does not match the number of gain factors');
    
    for i = 1 : nTrials
       trial = Shelter(ctl, config);
       trial.gain_triggers = gain_seq{i};
       trial.timeout_seconds = config.timeout.timeout_seconds;
       seq.add(trial); 
    end
end

