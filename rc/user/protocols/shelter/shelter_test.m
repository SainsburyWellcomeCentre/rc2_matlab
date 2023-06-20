function seq = shelter_test(ctl)

    config = config_ae_test(true);

    % setup the protocol sequence
    seq = ProtocolSequence(ctl);
    
    for i = 1 : 20
       seq.add(Shelter(ctl, config)) 
    end
end

