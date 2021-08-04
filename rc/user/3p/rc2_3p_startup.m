% saving Analog Input
config = config_default_3P(false);
%%

ctl = Controller(config);
%%
ctl.saver.save_to = 'D:\Data\3PData';

% Mouse ID
animalid = 'Animals ID:';
ctl.saver.prefix = input(animalid);
%ctl.saver.prefix = 'Test_210628SW_3';
% Experiment type/date and number
expnr='Date and exp name:';
ctl.saver.suffix = input(expnr);
%ctl.saver.suffix = 'binoc-1';
%ctl.saver.suffix = 'left-1';
%ctl.saver.suffix = 'right-1';

%%
ctl.prepare_acq();

%%
ctl.start_acq();

% start vis stim

  