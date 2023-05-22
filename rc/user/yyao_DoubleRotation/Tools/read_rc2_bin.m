function [data, dt, chan_names, config] = read_rc2_bin(fname_bin)
    %%[data, dt, chan_names, config] = READ_RC2_BIN(fname_bin)
    %   Read and transform data from a .bin & .cfg pair.
    %       Inputs:
    %           fname_bin - string, filename of .bin file (should include the
    %                           .bin extension)
    %       Outputs:
    %           data - TxN double, T - sample points, N - channels
    %           dt - time step between sample points
    %           chan_names - 1xN string array containing names of the N
    %                       channels
    %           config - structure containing information in the .cfg file   
    %
    %   Assumes that the .bin is paired with a .cfg in the same directory.
    %   Uses the .cfg to obtain N (number of channels) and the offsets and
    %   scales of each channel.
    %   20200304 - currently assumes that the data was saved by transforming
    %   voltages between -10 and 10V into 16-bit signed integers.
    
    % Assume .cfg exists in same directory
    fname_cfg       = regexprep(fname_bin, '.bin\>', '.cfg');
    % Parse the .cfg
    config          = read_rc2_config(fname_cfg);
    
    % Number of channels
    chan_names      = config.nidaq.ai.channel_names;
    n_channels      = length(chan_names);
    
    % Read the binary data
    data            = read_bin(fname_bin, n_channels);
    
    % Use config file to determine offset and scale of each channel
    offsets         = config.nidaq.ai.offset;
    scales          = config.nidaq.ai.scale;
    
    % Transform the data.
    %   Convert 16-bit integer to volts between -10 and 10.
    data            = -10 + 20*(data + 2^15)/2^16;
    %   Use offset and scale to transform to correct units (cm/s etc.)
    data            = data_transform(data, offsets, scales);
    
    % Also return sampling period
    dt              =  1/config.nidaq.ai.rate;
end


function data = read_bin(fname, n_chan)
    %data = READ_BIN(fname, n_chan)
    % Reads binary data saved by rc2 (int16)
    %   Channels along the columns, samples along the rows.
    
    fid = fopen(fname, 'r');
    data = fread(fid, 'int16');
    data = reshape(data, n_chan, [])';
    fclose(fid);
end


function data = data_transform(data, offset, scale)
    % transform each channel of data matrix (written to convert volts
    % to cm/s etc.) by subtracting offset and multiplying by scale
    % data - n x m matrix (channels along rows)
    % offset, scale - n x 1 arrays
    
    data = bsxfun(@minus, data, offset);
    data = bsxfun(@times, data, scale);
end


function config = read_rc2_config(cfg_fname) %#ok<*STOUT>
    %%config = PARSE_RC2_CONFIG(cfg_fname)
    %  
    %  Convert the config file saved by rc2 into a structure.
    %
    %   The config file is a sequence of key/value pairs. It only performs a
    %   very simple parse, so if there are new lines etc. in any of the filenames
    %   etc. we have a problem...
    
    
    
    % open, read, close config file
    fid = fopen(cfg_fname, 'r');
    str = fread(fid, 'char');
    fclose(fid);
    
    % convert to character row array
    str = char(str(:)');
    
    % split blocks on four newline characters
    str_blocks = strsplit(str, '\n\n\n\n');
    
    % remove last entry, which is empty
    str_blocks(end) = [];
    
    % parse first block
    [keys, vals] = split_key_value(str_blocks{1});
    
    % convert string values into cell arrays, double arrays, scalar vals
    scalar = {'saving.ai_min_voltage', 'saving.ai_max_voltage', ...
        'nidaq.ai.rate', 'nidaq.ao.rate', 'nidaq.ao.idle_offset', ...
        'nidaq.co.init_delay', 'nidaq.co.low_samps', 'nidaq.co.high_samps', 'nidaq.ai.scale', 'nidaq.ai.offset'};
    cell_array = {'nidaq.ai.channel_names', 'nidaq.ai.channel_ids', ...
        'nidaq.ao.channel_names', 'nidaq.ao.channel_ids', ...
        'nidaq.co.channel_names', 'nidaq.co.channel_ids', ...
        'nidaq.do.channel_names', 'nidaq.do.channel_ids', ...
        'nidaq.di.channel_names', 'nidaq.di.channel_ids'};
    
    % do the conversion
    vals = convert_values(keys, vals, scalar, cell_array); %#ok<NASGU>
    
    % enter keys 
    for i = 1 : length(keys)
        cmd = sprintf('config.%s = vals{i};', keys{i});
        eval(cmd);
    end
    
    % remove first (nidaq) block, which we just 
    str_blocks(1) = [];
    
    % for conversion of protocol fields
    scalar = {'prot.start_pos', 'prot.stage_pos', 'prot.switch_pos', ...
        'prot.back_limit', 'prot.forward_limit', 'prot.start_dwell_time', ...
        'prot.handle_acquisition', 'prot.wait_for_reward', 'prot.log_trial', ...
        'prot.follow_previous_protocol', 'prot.reward.randomize', ...
        'prot.reward.min_time', 'prot.reward.max_time', 'prot.reward_duration'};
    
    
    % parse remaining protocols
    for i = 1 : length(str_blocks)
        
        % parse protocol blocks
        [keys, vals] = split_key_value(str_blocks{i});
        
        % convert some entries from strings to numbers
        vals = convert_values(keys, vals, scalar, {}); %#ok<NASGU>
        
        % store in the config structure
        for j = 1 : length(keys)
            subfield = strsplit(keys{j}, '.');
            cmd = sprintf('config.prot(i).%s = vals{j};', subfield{2});
            eval(cmd);
        end
    end
end





function [keys, vals] = split_key_value(str)
    %%[keys, vals] = split_key_value(str)
    %   Takes individual blocks and parses into keys and values
    
    % split key/value pairs on newlines
    str_lines = strsplit(str, '\n');
    
    % remove empty lines??
    keys = cell(1, length(str_lines));
    vals = cell(1, length(str_lines));
    
    
    for i = 1 : length(str_lines)
        
        % split line on the first equals character
        this_key = regexp(str_lines{i}, ' = ', 'split', 'once');
        
        % store keys and values
        keys{i} = this_key{1};
        vals{i} = this_key{2};
    end
end


function vals = convert_values(keys, vals, scalar, cell_array)

    % convert scalar and cell string arrays
    for i = 1 : length(keys)
        if any(strcmp(keys{i}, scalar))
            if strcmp(vals{i}, '---')
                vals{i} = nan;
            else
                vals{i} = eval(sprintf('[%s]', vals{i}));
            end
        end
        if any(strcmp(keys{i}, cell_array))
            vals{i} = strsplit(vals{i}, ',');
        end
    end
end