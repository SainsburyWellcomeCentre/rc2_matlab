dname = 'C:\Users\Margrie_Lab1\Documents\temp_data\CAA-1114768';
ul_per_s = 2/0.45;
block_idx = 19:26;
water_amount_ul = 0;

for i = 1 : length(block_idx)
    
    fname = sprintf('CAA-1114768_%i_001.bin', block_idx(i));
    fname = fullfile(dname, fname);
    [data, dt, chan_names, config] = read_rc2_bin(fname);
    pump_idx = strcmp(chan_names, 'pump');
    pump_data = data(:, pump_idx);
    time_up_s = sum(pump_data > 2.5)*dt;
    water_amount_ul = water_amount_ul + ul_per_s * time_up_s;
end

fprintf('%.2f ul\n', water_amount_ul);