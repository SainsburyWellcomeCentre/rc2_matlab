function data = read_bin(fname, n_chan)
    % Reads an int16 binary file.
    %
    % :param fname: The name of the file to read (either full filename or file on path).
    % :param n_chan: The number of channels contained in the file.
    % :return: :attr:`n_chan` x n matrix from the target file.

% open, read, reshape, close
fid = fopen(fname, 'r');
data = fread(fid, 'int16');
data = reshape(data, n_chan, [])';
fclose(fid);