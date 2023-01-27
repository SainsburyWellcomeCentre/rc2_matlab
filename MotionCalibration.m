clear all; close all; clc;

%% Parameters
axis = [0, 1];
Distances =  [400, 400, 400, 400, 400, 400, 400, 200, 200, 200, 200, 200, 200, 200, 100, 100, 100, 100, 100, 100, 100];
Velocities = [250, 200, 150, 100, 50,  25,  10,  250, 200, 150, 100, 50,  25,  10,  250, 200, 150, 100, 50,  25,  10 ];

Distances = [Distances -Distances];
Velocities = [Velocities Velocities];

%% Set up ensemble
disp('>>> Connecting and setting up ensemble.')
handle = EnsembleConnect;
EnsembleMotionEnable(handle, axis);

% Setup analog output from Ensemble servo
EnsembleAdvancedAnalogTrack(handle, axis, 0, 4, 0.0005, 2.5);

%% Experiment
% Run a few home commands to rotate the wheel fully twice
for i = 1:2
    disp('>>> Homing ensemble.')
    EnsembleMotionHome(handle, axis);
    pause(2);
end

% Test motion
for i = 1:length(Distances)
    disp(['>>> Motion: ' num2str(i) ' of ' num2str(length(Distances))]);
    EnsembleMotionLinear(handle, axis, [Distances(i) Distances(i)], [Velocities(i) Velocities(i)]);
    pause(2);
end