%Pipeline Theme_park data analysis 
%Created by Agatha A. on 05/07/2021

%Run anlysis and save plots for all session from 1 animal

animal_id = 'CAA-1114768';
save_figs = true; %want to save the plots?
dname = strcat('C:\Users\Margrie_Lab1\Documents\temp_data\', animal_id);
set(0,'DefaultFigureVisible','off');

if ~isfolder(dname)
    fprintf('Animal does not exist.');

else
end
 
    dir_all = dir(dname);
    dir_name = {dir_all(:).name};
    only_bins = contains(dir_name, '.bin');
    all_blocks = dir_name(only_bins);
    
    
     for i = 1 : length(all_blocks)
    fname = all_blocks(i);
    fparts = strsplit(fname{1}, '_');
    block_idx = fparts{2};
    bin_fname = fullfile(dname, fname);
    bin_fname = strcat("",bin_fname,"");
    analyze_and_plot_licking_data_aa(bin_fname,animal_id, block_idx, dname);
    fprintf('Saving block %i\n,', block_idx)
  
     end

 %else
% end
