clear; 
% close all; 
clc;

%% set up controller
config = config_LickTest();
ctl = controller_LickTest(config);


%% trial
config.lick_detect.enable                   = true;     
config.lick_detect.lick_threshold           = 1;
config.lick_detect.n_windows                = 60;      
config.lick_detect.window_size_ms           = 250;
config.lick_detect.n_consecutive_windows    = 1;
%     protocolconfig.lick_detect.n_lick_windows           = protocolconfig.lick_detect.n_consecutive_windows;
config.lick_detect.n_lick_windows           = 3;
config.lick_detect.detection_trigger_type   = 1;
config.lick_detect.delay                    = 15;       % delay of LickDetect trigger from TrialStart (in sec)

ctl.lick_detector = LickDetect_DoubleRotation(ctl, config);

trialTest = trial_LickTest(ctl, config);
trialTest.run();