function config = load_config()
    % Auxiliary function for manually selecting a config file and loading it.
    % Opens a user interface for selecting a config file.
    %
    % :return: A user-defined configuration structure.

% select config file
this_dir = fileparts(mfilename('fullpath'));
fname = uigetfile(fullfile(this_dir, '..', 'main', 'configs', '*.m'), 'Load configuration file...');
if fname == 0; fprintf('No config selected\n'); return; end

% load config file
fn = str2func(strrep(fname, '.m', ''));
config = fn();
