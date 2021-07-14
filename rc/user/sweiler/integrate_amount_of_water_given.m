function [water_amount_ul] = integrate_amount_of_water_given(dname, block_idx, animal_id)

%modified on 05/07/2021 by Agatha A. to be able to run it as a function

ul_per_s = 2/0.45;
block_idx = block_idx;
water_amount_ul = 0;

for i = 1 : length(block_idx)
    
    gname = sprintf(strcat(animal_id,'_%i_001.bin'), block_idx(i));
    gname = fullfile(dname, gname);
    [data, dt, chan_names, config] = read_rc2_bin(gname);
    pump_idx = strcmp(chan_names, 'pump');
    pump_data = data(:, pump_idx);
    time_up_s = sum(pump_data > 2.5)*dt;
    water_amount_ul = fix(water_amount_ul + ul_per_s * time_up_s);
end

fprintf('%.2f ul\n', water_amount_ul);
end
