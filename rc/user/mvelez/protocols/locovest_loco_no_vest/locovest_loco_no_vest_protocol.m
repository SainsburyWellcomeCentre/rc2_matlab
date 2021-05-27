function seq = locovest_loco_no_vest_protocol(ctl)

fname = 'locovest_loco_protocol_sequence.mat';

load(fname, 'order', 'config', 'prot');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

% it will loop n_loops number of times
for i = 1 : length(order)
    if order(i) == prot.locovest
        locovest = Coupled(ctl, config);
        seq.add(locovest);
    elseif order(i) == 2
        loco = EncoderOnly(ctl, config);
        loco.integrate_using = 'pc';
        seq.add(loco);
    end
end
