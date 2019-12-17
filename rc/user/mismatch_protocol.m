function seq = mismatch_protocol(ctl)

fname = 'mismatch_protocol_sequence.mat';

load(fname, 'order', 'config', 'switch_pos');

% setup the protocol sequence
seq = ProtocolSequence(ctl);

% it will loop n_loops number of times
for i = 1 : length(order)
    if order(i) == 1
        lv2l = LocoVest2Loco(ctl, config);
        lv2l.switch_pos = switch_pos(i);
        seq.add(lv2l);
    elseif order(i) == 2
        l2lv = Loco2LocoVest(ctl, config);
        l2lv.switch_pos = switch_pos(i);
        seq.add(l2lv);
    end
end