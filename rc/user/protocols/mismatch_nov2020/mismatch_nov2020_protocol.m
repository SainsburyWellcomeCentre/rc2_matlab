function seq = mismatch_nov2020_protocol(ctl)

fname = 'mismatch_nov2020_protocol_sequence.mat';

load(fname, 'prot', 'order', 'config', 'switch_pos');

% setup the protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = true;

mismatch_duration = 0.2;

% it will loop n_loops number of times
for i = 1 : length(order)
    
    if order(i) == prot.mt_mismatch_down
        
        mt_down = CoupledMismatch(ctl, config);
        mt_down.switch_pos = switch_pos(i);
        mt_down.gain_direction = 'down';
        mt_down.mismatch_duration = mismatch_duration;
        seq.add(mt_down);
        
    elseif order(i) == prot.mt_mismatch_up
        
        mt_up = CoupledMismatch(ctl, config);
        mt_up.switch_pos = switch_pos(i);
        mt_up.gain_direction = 'up';
        mt_up.mismatch_duration = mismatch_duration;
        seq.add(mt_up);
        
    elseif order(i) == prot.m_mismatch_down
        
        m_down = EncoderOnlyMismatch(ctl, config);
        m_down.switch_pos = switch_pos(i);
        m_down.gain_direction = 'down';
        m_down.mismatch_duration = mismatch_duration;
        seq.add(m_down);
        
    elseif order(i) == prot.m_mismatch_up
        
        m_up = EncoderOnlyMismatch(ctl, config);
        m_up.switch_pos = switch_pos(i);
        m_up.gain_direction = 'up';
        m_up.mismatch_duration = mismatch_duration;
        seq.add(m_up);
        
    end
end