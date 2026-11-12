function [trial_order, fnames] = create_variable_distance_protocol_sequence()
% Create a randomized sequence of long and short track distances and process velocity profile filenames.
% Output:
%   trial_order - randomized sequence of track distances (double array)


% restart random number generator for reproducibility
rng(1);

% number of trials for each track type
n_trials = 20; % adjust as needed

% define the TWO distances that are mixed across trials
long_track = 1200; % in cm
short_track = 600; % in cm


% Create initial array with all long and short tracks
trial_order = [repmat(long_track, n_trials, 1); repmat(short_track, n_trials, 1)];

% Randomize the order
trial_order = trial_order(randperm(length(trial_order)));

% Assign 'long' or 'short' to fnames according to trial_order values
fnames = cell(size(trial_order));
for i = 1:length(trial_order)
	if trial_order(i) == long_track
		fnames{i} = 'long';
	elseif trial_order(i) == short_track
		fnames{i} = 'short';
	else
		fnames{i} = 'unknown'; %%%%%%%%idk if it has to be a full name
	end
end


this_file_fullpath = [mfilename('fullpath') '.m'];

save('locovest_variable_distance_protocol_sequence.mat', 'fnames', 'trial_order', 'this_file_fullpath');