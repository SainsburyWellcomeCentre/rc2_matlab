function data = read_bin(fname, n_chan)

fid = fopen(fname, 'r');
data = fread(fid, 'int16');
data = reshape(data, n_chan, [])';