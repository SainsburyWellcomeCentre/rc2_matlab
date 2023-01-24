clear all; close all; clc;

%% set up controller
config = config_default();
ctl = RC2Controller(config);

% trial
trialTest = RotationTest(ctl, config, 500);
trialTest.run();