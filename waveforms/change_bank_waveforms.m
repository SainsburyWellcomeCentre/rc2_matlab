basedir = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\waveforms';

% plot the current waveforms
figure
for i = 1 : 10
    fname = fullfile(basedir, sprintf('CA_529_2_trn11_001_single_trial_%03i.bin', i));
    data = read_bin(fname, 1);
    t = (0:length(data)-1)*(1/10000);
    subplot(5, 2, i)
    data = -10 + 20*(data + 2^15)/2^16;
    plot(t, (100/2.5)*(data-0.5))
    title(num2str(i))
end



%%
% chop this much from the start of each wavefrom
fs = 10000;
start = [0.4, 0.5, 0, 22, 0, 32.5, 2.5, 0, 0, 0.5];
start_idx = 1 + start*fs;
end_pad = fs;

for i = 1 : 10
    
    fname = fullfile(basedir, sprintf('CA_529_2_trn11_001_single_trial_%03i.bin', i));
    data = read_bin(fname, 1);
    
    % cut at beginning and append to end
    new_data = data(start_idx(i):end);
    new_data(end+1:end+end_pad) = new_data(end);
    
    % overwrite the waveform
    fid = fopen(fname, 'w');
    fwrite(fid, new_data, 'int16');
    fclose(fid);
end