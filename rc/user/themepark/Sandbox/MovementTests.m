clear all; close all; clc;

%% Parameters
Distances =  [400, 400, 400, 400, 400, 200, 200, 200, 200, 200, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];
Velocities = [250, 150, 100, 50,  25,  250, 150, 100, 50,  25,  250, 150, 100, 50,  25,  250,150,100,50, 25];
axis = 1;

Distances = [Distances -Distances];
Velocities = [Velocities Velocities];

%% Ensemble setup
handle = EnsembleConnect;

% Enabling and homing
disp('>>> Homing');
EnsembleMotionEnable(handle, axis);
EnsembleMotionHome(handle, axis);

% Set motion mode
EnsembleMotionSetupIncremental(handle);
EnsembleMotionWaitMode(handle, EnsembleWaitType.MoveDone);

pause(1);
%% Motion loop
for i = 1:length(Distances)
    disp(['>>> Motion ' num2str(i) ' of ' num2str(length(Distances))]);
    EnsembleMotionLinear(handle, axis, Distances(i), Velocities(i));

    pause(1);
end

%% Cleanup
EnsembleDisconnect();