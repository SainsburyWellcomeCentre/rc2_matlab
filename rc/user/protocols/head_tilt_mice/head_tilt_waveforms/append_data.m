function append_data()
% append 1s to the traces of CA_529_2 as they cause problems with the new
% setup

% get file info
dirinfo = dir('CA_529_2*');

% should be 8 such files
assert(length(dirinfo) == 8);

% sample rate of the trace (I know this)
fs = 10e3;

% for each file
for i = 1 : length(dirinfo)
    
    % read the data
    data = read_bin(dirinfo(i).name, 1);
    
    % append the last value for 1s
    data = [data; data(end)*ones(fs, 1)];
    
    % new filename
    new_fname = strrep(dirinfo(i).name, '.bin', '_appended.bin');
    
    % write data
    write_bin(new_fname, data)
    
end



function write_bin(fname, data)

fid = fopen(fname, 'w');
fwrite(fid, data(:), 'int16');
fclose(fid);