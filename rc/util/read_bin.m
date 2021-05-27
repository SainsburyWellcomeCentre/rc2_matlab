function data = read_bin(fname, n_chan)
%%data = READ_BIN(fname, n_chan)
%   Reads an int16 binary file.
%   Inputs:
%       fname - name of the file to read (either full filename or file on
%       the path
%       n_chan - number of channels contained in the file

% open, read, reshape, close
fid = fopen(fname, 'r');
data = fread(fid, 'int16');
data = reshape(data, n_chan, [])';
fclose(fid);