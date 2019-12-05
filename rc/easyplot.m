
fname = 'C:\Users\Mateo\Desktop\DefaultData\201911131403\201911131403_37_008.bin';
data = read_bin(fname, 7);
data = -10 + 20*(data + 2^15)/2^16;

%%
data_t = ctl.data_transform.transform(data);

figure(3)
hold on
plot(data_t(:, 1))