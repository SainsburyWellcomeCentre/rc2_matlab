function [trial_order, fnames, protocol_id] = create_passive_protocol_sequence_motion_clouds()

% Parameters
num_motion_clouds = 37;  % <--- Set this manually
rng(1);  % For reproducibility

% Directory containing speed profile .bin files
data_dir = fullfile(pwd, 'passive_waveforms_motion_clouds');
track_fnames = dir(fullfile(data_dir, '*.bin'));
track_fnames = {track_fnames(:).name};

if length(track_fnames) ~= 2
    error('Expected exactly 2 speed profile .bin files.');
end

% Protocol IDs (unchanged)
protocol_id.vest_with_flow = 1;
protocol_id.visual_flow = 2;
protocol_id.vest_darkness = 3;
protocol_ids = [protocol_id.vest_with_flow, protocol_id.visual_flow, protocol_id.vest_darkness];

% Initialize
trial_order_half = [];
speed_profile_half = [];

% Randomly assign speed profiles A or B to each motion cloud
rand_assignment = randi([1, 2], 1, num_motion_clouds);  % 1 = A, 2 = B

for i = 1:num_motion_clouds
    % Randomize protocol order
    randomized_protocols = protocol_ids(randperm(3));
    
    % Save triplet for this cloud
    trial_order_half = [trial_order_half, randomized_protocols];
    
    % Repeat assigned speed profile 3 times (once per protocol)
    speed_profile_half = [speed_profile_half, repmat(rand_assignment(i), 1, 3)];
end

% Mirror speed profile assignment: flip speed profiles
speed_profile_half_mirror = 3 - speed_profile_half;  % if 1->2, 2->1

% Full sequence
trial_order = [trial_order_half, trial_order_half]';
speed_profile_sequence = [speed_profile_half, speed_profile_half_mirror]';

% Map to filenames
fnames = track_fnames(speed_profile_sequence);
fnames = cellfun(@(x)(fullfile(data_dir, x)), fnames, 'UniformOutput', false);
fnames = fnames(:);  % column format

% Save
save('passive_protocol_sequence_motion_clouds.mat', 'fnames', 'protocol_id', 'trial_order');

end
