%% Test script for loading waveforms and playing on an ensemble controller
clear all; close all; clc;

%% set up ni device
disp('>>> Loading configuration.')
config = config_default();
ni = NI(config);

%% set up soloist
disp('>>> Connecting and homing ensemble.')
handle = EnsembleConnect;
EnsembleMotionEnable(handle, axis);
EnsembleMotionHome(handle, axis);

% EnsembleAdvancedAnalogControlOn(handle, 0, 0, 0.01, 0);
EnsembleAdvancedAnalogTrack(handle, 0, 0, 0, 0.01, 0);

%% load a waveform for playback
disp('>>> Starting wave playback.')
wave_fname = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\rc\user\mvelez(not in use)\waveforms\CA_529_2_trn11_001_single_trial_001.bin';
w = double(read_bin(wave_fname, 1)); % file must be single channel
waveform = -10 + 20*(w(:, 1) + 2^15)/2^16;

% load waveform to the nidaq
ni.ao_write(waveform);

% start ni stuff
ni.start_acq();
ni.ao_start();

%% termination loop
while ni.ao.task.IsRunning
    disp(ni.ao.task.IsRunning);
end

ni.stop_all();