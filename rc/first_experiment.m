
c = Coupled(ctl, config);
c.back_limit = 800;
c.log_trial = true;

s = StageOnly(ctl, config);
seq = ProtocolSequence(ctl);

seq.add(c);
seq.add(s);

seq.run()
