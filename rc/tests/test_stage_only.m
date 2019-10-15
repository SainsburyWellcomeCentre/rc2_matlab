% test output protocol

fname = 'test.bin';
rate = 10000;
dur = 2;
n_samples = dur*rate;
a = 0.5+0.5*randn(n_samples, 1);
a(a>2) = 2;
a(a<0) = 0;
a(end) = 0.5;
a = int16(-2^15 + 2^16*(a+10)/20);

fid = fopen(fname, 'w');
fwrite(fid, a, 'int16');
fclose(fid);



%%
s = StageOnly(ctl, fname);
s.run();