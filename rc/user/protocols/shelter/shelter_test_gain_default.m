function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    nTrials = 10;
    gain_seq = {[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1]}; % Defines the gain pins high or low. e.g. [1, 1] is both pins high = default gain. [0, 0] is both bins low = gain down. [1, 0] is HIGH high = gain up.
    
    assert(nTrials == length(gain_seq), 'Warning: number of trials does not match the number of gain factors');
    
    for i = 1 : nTrials
       trial = Shelter(ctl, config);
       trial.gain_triggers = gain_seq{i};
       trial.timeout_seconds = config.timeout.timeout_seconds;
       seq.add(trial); 
    end
end

