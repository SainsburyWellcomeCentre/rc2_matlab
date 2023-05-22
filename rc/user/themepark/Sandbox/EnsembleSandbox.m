clear all; close all; clc;

%% MATLAB APPROACH
% Parameters
Distance = 150;
Vel = [150 150];
axis = [0,1]; 

% Connect to the Ensemble
handle = EnsembleConnect;

% Enabling and Homing
EnsembleMotionEnable(handle, axis);
EnsembleMotionHome(handle, axis);

% Set motion mode
EnsembleMotionSetupIncremental(handle);
EnsembleMotionWaitMode(handle, EnsembleWaitType.MoveDone);
EnsembleMotionSetupScurve(handle, 50);

% Motion
EnsembleCommandExecute(handle, 'VELOCITY ON');
velocityMode = EnsembleStatusGetMode(handle, EnsembleModeType.VelocityMode);
scurveValue = EnsembleStatusGetMode(handle, EnsembleModeType.ScurveValue);
EnsembleMotionLinear(handle, axis, [Distance -Distance], [Vel(1) Vel(1)]);
EnsembleMotionLinear(handle, axis, [Distance -Distance], [Vel(2) Vel(2)]);
EnsembleCommandExecute(handle, 'VELOCITY OFF');
velocityMode2 = EnsembleStatusGetMode(handle, EnsembleModeType.VelocityMode);
EnsembleMotionLinear(handle, axis, [Distance -Distance], [100 100]);

% Disconnect
EnsembleDisconnect();

% %% COMMAND APPROACH
% axis = [0,1];
% handle = EnsembleConnect;
% 
% EnsembleCommandExecute(handle, 'WAIT MODE MOVEDONE');
% EnsembleCommandExecute(handle, 'RAMP MODE RATE');
% EnsembleCommandExecute(handle, 'RAMP RATE ACCEL 25');
% EnsembleCommandExecute(handle, 'RAMP RATE DECEL 15');
% EnsembleCommandExecute(handle, 'SCURVE 50');
% EnsembleCommandExecute(handle, 'ENABLE L');
% 
% EnsembleCommandExecute(handle, 'HALT');
% EnsembleCommandExecute(handle, 'VELOCITY ON');
% EnsembleCommandExecute(handle, 'LINEAR L 40 F 150');
% EnsembleCommandExecute(handle, 'LINEAR L 50 F 200');
% EnsembleCommandExecute(handle, 'VELOCITY OFF');
% 
% EnsembleCommandExecute(handle, 'START');
% 
% EnsembleDisconnect;

%% PROGRAM APPROACH
handle = EnsembleConnect;



EnsembleDisconnect;