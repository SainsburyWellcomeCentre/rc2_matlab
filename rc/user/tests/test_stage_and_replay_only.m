%%
c = Coupled(ctl, config);
c.start_pos = 500;
c.log_trial = 1;
c.log_fname = 'test.bin';

%%
s = StageOnly(ctl, config);
s.wave_fname = 'test.bin';
s.start_pos = 500;
s.initiate_trial = 1;

%%
r = ReplayOnly(ctl, config);
r.wave_fname = 'test.bin';
r.start_pos = 500;
r.initiate_trial = 1;