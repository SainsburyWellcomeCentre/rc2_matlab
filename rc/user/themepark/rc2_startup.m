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

% setup configuration
config = load_config();
if isempty(config), return, end

% main controller object
ctl = RC2Controller(config);

% gui interface object
gui = rc2guiController(ctl, config);
