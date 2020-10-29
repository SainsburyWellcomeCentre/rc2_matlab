function config = load_config()

% select config file
this_dir = fileparts(mfilename('fullpath'));
fname = uigetfile(fullfile(this_dir, 'main', 'configs', '*.m'), 'Load configuration file...');
if fname == 0; fprintf('No config selected\n'); return; end

% load config file
fn = str2func(strrep(fname, '.m', ''));
config = fn();
