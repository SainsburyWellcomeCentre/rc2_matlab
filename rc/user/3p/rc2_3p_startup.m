% saving Analog Input
config = config_default_3P(false);
ctl = Controller(config);

ctl.saver.save_to = 'D:\Data\Default3PData';

% Mouse ID
ctl.saver.prefix = 'CAA-1111111';

% Experiment type and number (NOTE: must manually increment number each
% time!)
ctl.saver.suffix = 'blank-1';
%ctl.saver.suffix = 'binoc-1';
%ctl.saver.suffix = 'left-1';
%ctl.saver.suffix = 'right-1';


ctl.prepare_acq();
ctl.start_acq();
  