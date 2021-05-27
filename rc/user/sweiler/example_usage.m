% OPTIONS
animal_id = 'CAA-1000000';
session_id = 'trn_1';



%% SETUP
config = config_sweiler();
ctl = RC2Controller(config);

ctl.saver.prefix = animal_id;
ctl.saver.suffix = session_id;


%% RUN ACQUISITION
ctl.prepare_acq();
ctl.start_acq();

%% send trigger to visual stimulus computer to start
ctl.visual_stimulus.on()

% at end of recording stop acquisition
% ctl.stop_acq();
