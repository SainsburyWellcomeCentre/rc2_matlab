%% RC2_DoubleRotation Visual Stimuli startup
    
% add user folder
[path, ~] = fileparts(mfilename("fullpath"));
addpath(genpath(path));
clear path;
    
% setup configuration
config = config_visstim();
if isempty(config), return, end
config.connection.local_ip_address = '172.24.242.158'; % ip of visualsti PC
config.connection.local_port_prepare = 43056;
config.connection.local_port_stimulus = 43057;

% prepare visual stimuli computer
visstim = ThemeParkVisualStimulusComputer(config);

