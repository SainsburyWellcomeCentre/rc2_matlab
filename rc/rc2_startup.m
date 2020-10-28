% Main startup script to interface with the rollercoaster setup
%
% leaves 3 variables in the MATLAB workspace
%       config - general configuration parameters *at startup* (changing
%           these after startup will have no effect, unless you rerun
%           Controller(config) etc.
%       ctl - main object for interfacing with the setup, contains several
%           objects for interaction with each component of the setup as
%           well as display
%       gui - main object for interfacing with the gui. unlikely there will
%           be much use for using it other than debugging


% select config file
this_dir = fileparts(mfilename('fullpath'));
fname = uigetfile(fullfile(this_dir, 'main', 'configs', '*.m'), 'Load configuration file...');
if fname == 0; fprintf('No config selected\n'); return; end

% load config file
fn = str2func(strrep(fname, '.m', ''));
config = fn();

% main controller object
ctl = Controller(config);

% gui interface object
gui = rc2guiController(ctl, config);
