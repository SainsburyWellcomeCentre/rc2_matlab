clear all; close all; clc;

%% set up controller
config = config_default();
ctl = RC2Controller(config);

% trial
wform = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\rc\user\mvelez(not in use)\waveforms\CA_529_2_trn11_001_single_trial_001.bin';
trialTest = WaveformOnly(ctl, config, wform);
trialTest.run();