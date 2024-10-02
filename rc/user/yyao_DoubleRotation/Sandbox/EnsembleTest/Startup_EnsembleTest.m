clear; 
% close all; 
clc;

%% set up controller
config = config_EnsembleTest();
% config.ensemble.target_axes = [0 NaN];
% config.ensemble.target_axes = [NaN 1];
config.ensemble.target_axes = [0 1];
ctl = Controller_EnsembleTest(config);


%% trial
% wform = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\rc\user\mvelez(not in use)\waveforms\CA_529_2_trn11_001_single_trial_001.bin';
trial.stage.enable_motion = true;
trial.stage.motion_time = 30;
trial.stage.peakwidth = 2.5;
trial.stage.central.enable = true;
trial.stage.central.distance = -90;
trial.stage.central.max_vel = 40; 
trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
trial.stage.outer.enable = true;
trial.stage.outer.distance = -90;
trial.stage.outer.max_vel = 40; 
trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
wform = voltagewaveform_generator_linear(trial.stage, 10000);
% trialTest = WaveformOnly(ctl, config, wform);
trialTest = WaveformDrivenRotation_EnsembleTest(ctl, config, wform);
trialTest.run();