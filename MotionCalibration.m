clear all; close all; clc;

%% Parameters
axis = [0, 1];

%% Set up ensemble
disp('>>> Connecting and homing ensemble.')
handle = EnsembleConnect;
EnsembleMotionEnable(handle, axis);
EnsembleMotionHome(handle, axis);

% Setup analog output from Ensemble servo
EnsembleAdvancedAnalogTrack(handle, axis, 0, 4, 0.0005, 2.5);

% Test motion
EnsembleMotionLinear(handle, axis, [100 100], [50 50]);
EnsembleMotionLinear(handle, axis, [-100 -100], [100 100]);
EnsembleMotionLinear(handle, axis, [100 100], [50 50]);
EnsembleMotionLinear(handle, axis, [-100 -100], [100 100]);