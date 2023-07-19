function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    nTrials = 10;
    % gain_seq defines the gain levels for each trial in the protocol. The actual gain values applied in each case depend on what is set in options.h for GAIN_DEFAULT_VAL, GAIN_UP_VAL, GAIN_DOWN_VAL, GAIN_ZERO_VAL
    % [1, 1] = default gain (GAIN_DEFAULT_VAL)
    % [1, 0] = gain up (GAIN_UP_VAL)
    % [0, 1] = gain down (GAIN_DOWN_VAL)
    % [0, 0] = gain zero (GAIN_ZERO_VAL)
    gain_seq = {[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1]}; 
    
    assert(nTrials == length(gain_seq), 'Warning: number of trials does not match the number of gain factors');
    
    for i = 1 : nTrials
       trial = Shelter(ctl, config);
       trial.gain_triggers = gain_seq{i};
       trial.timeout_seconds = config.timeout.timeout_seconds;
       seq.add(trial); 
    end
end

