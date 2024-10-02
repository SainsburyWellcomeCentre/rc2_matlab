function [timebase,signal,online_data] = LickingData_Reading(bin_fname)

% if ~ (exist bin_fname)
%     bin_fname = 'D:\raw_data\CAA-1119727\CAA-1119727_230630_h05_LickTraining_Stage1.bin';
% end

% load the raw data and online data (if it exists)
mat_fname                   = strrep(bin_fname, '.bin', '_themepark.mat');  

[data, dt, channel_names, ~] = read_rc2_bin(bin_fname);   
online_data_exists          = isfile(mat_fname);

if online_data_exists
    online_data                 = load(mat_fname);  
else
    online_data                 = [];
end

% channel id of various signals
idx.stage_central_idx           = strcmp(channel_names, 'stage_central');   
idx.stage_outer_idx             = strcmp(channel_names, 'stage_outer');  
idx.LickDetect_trigger_chan_idx = strcmp(channel_names, 'LickDetect_trigger');   
idx.lick_chan_idx               = strcmp(channel_names, 'lick');                               
idx.pump_chan_idx               = strcmp(channel_names, 'pump');  
idx.visstim_chan_idx            = strcmp(channel_names, 'VisualStim_trigger');
idx.photodiodeL_idx             = strcmp(channel_names, 'photodiode_left'); 

% time base of data
timebase                    = (0:size(data, 1)-1)*dt;

Voltage2VelocityRatio = 10;
% signals
signal.stage_central_signal        = data(:, idx.stage_central_idx)*Voltage2VelocityRatio;              % velocity
signal.stage_outer_signal          = data(:, idx.stage_outer_idx)*Voltage2VelocityRatio;                % velocity
signal.LickDetect_trigger_signal   = data(:, idx.LickDetect_trigger_chan_idx);                          % voltage
signal.photodiodeL_signal          = data(:, idx.photodiodeL_idx);
signal.lick_signal                 = data(:, idx.lick_chan_idx);
signal.pump_signal                 = data(:, idx.pump_chan_idx);
signal.visstim_signal              = data(:, idx.visstim_chan_idx);

end