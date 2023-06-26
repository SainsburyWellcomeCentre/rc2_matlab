function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    
    for i = 1 : 20
       trial = Shelter(ctl, config);
       trial.gain = config.stage.gain_seq(i);
       seq.add(trial); 
    end
end

