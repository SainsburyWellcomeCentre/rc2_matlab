% Main startup script to interface with the rollercoaster setup
%
% leaves 3 variables in the MATLAB workspace
%       config - general configuration parameters *at startup* (changing
%           these after startup will have no effect, unless you rerun
%           RC2Controller(config) etc.
%       ctl - main object for interfacing with the setup, contains several
%           objects for interaction with each component of the setup as
%           well as display
%       gui - main object for interfacing with the gui. unlikely there will
%           be much use for using it other than debugging

%% RC2_DoubleRotation_startup

% setup configuration
config = config_yyao();
config.connection.remote_ip = '172.24.242.177';
config.connection.remote_port_prepare = 43056;
config.connection.remote_port_stimulus = 43057;
if isempty(config), return, end

% main controller object
ctl = RC2_DoubleRotation_Controller(config);    

% gui interface object
gui = RC2_DoubleRotation_GUIController(ctl, config);