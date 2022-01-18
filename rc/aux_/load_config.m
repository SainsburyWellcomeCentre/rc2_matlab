function config = load_config()
%%LOAD_CONFIG Auxiliary function for manually selecting a config file and
%%loading it
%
%   CONFIG = load_config() opens a user interface for selecting a config
%   file. Then performs the loading and returns the configuration structure
%   in CONFIG.

% select config file
this_dir = fileparts(mfilename('fullpath'));
fname = uigetfile(fullfile(this_dir, '..', 'main', 'configs', '*.m'), 'Load configuration file...');
if fname == 0; fprintf('No config selected\n'); return; end

% load config file
fn = str2func(strrep(fname, '.m', ''));
config = fn();
