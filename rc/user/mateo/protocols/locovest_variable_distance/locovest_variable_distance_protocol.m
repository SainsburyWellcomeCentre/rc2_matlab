function seq = locovest_variable_distance_protocol(ctl)
%% seq = LOCOVEST_VARIABLE_DISTANCE_PROTOCOL(ctl)
%   Plays a sequence of only 'locovest' trials.
%   Each trial's track distance is defined in
%   'locovest_variable_distance_protocol_sequence.mat' by the variable 'trial_order'.
%
%   This version supports arbitrary (continuous) distance values.

% --- Load trial distances
load('locovest_variable_distance_protocol_sequence.mat', 'trial_order');

if ~exist('trial_order', 'var')
    error('Variable ''trial_order'' not found in locovest_variable_distance_protocol_sequence.mat.');
end
if ~isnumeric(trial_order)
    error('Expected ''trial_order'' to be a numeric vector of distances.');
end

% --- Define protocol_id manually (only locovest)
protocol_id.locovest = 1;

% --- Fixed parameters
reward_position = 250;
back_distance   = 5;

% --- Create protocol sequence
seq = ProtocolSequence(ctl);
seq.randomize_reward = false;

% --- Build each trial
for i = 1:length(trial_order)
    distance = trial_order(i);

    % Configure per-trial stage distances
    config.stage.start_pos      = reward_position + distance;
    config.stage.back_limit     = config.stage.start_pos + back_distance;
    config.stage.forward_limit  = reward_position;

    % --- Setup locovest protocol
    locovest = Coupled(ctl, config);
    locovest.log_trial = true;

%     % Filename (saves bin files for every trial, important when there is replay, i.e., not important for this protocol)
%     fname_ = sprintf('%s_%s_%03i_single_trial_prot_%02i_%03i.bin', ...
%         ctl.saver.prefix, ...
%         ctl.saver.suffix, ...
%         ctl.saver.index, ...
%         protocol_id.locovest, ...
%         i);
% 
%     locovest.log_fname = fullfile(ctl.saver.save_to, ctl.saver.prefix, fname_);

    % Disable visual stimulus
    locovest.enable_vis_stim = false;

    % Add protocol to sequence
    seq.add(locovest);
end

end
