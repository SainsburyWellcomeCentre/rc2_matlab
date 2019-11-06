function seq = setup_training_sequence(ctl, config, reward_position, distance, back_distance, n_loops)
%%seq = SETUP_TRAINING_SEQUENCE(ctl, config, reward_position, distance, back_distance)
%   Sets up a protocol sequence for training.
%       Inputs:
%               ctl:                controller object
%               config:             general configuration structure
%               reward_position:    position along the controller
%               distance:           distance to start from reward position
%               back_distance:      amount to move backward before stopping
%       Outputs:
%               seq:                protocol sequence


% setup a single training protocol
coupled = Coupled(ctl, config);
coupled.start_pos = reward_position + distance;
coupled.back_limit = coupled.start_pos + back_distance;
coupled.forward_limit = reward_position;
coupled.direction = 'forward_and_backward';
coupled.vel_source = 'teensy';


% setup the protocol sequence
seq = ProtocolSequence(rc.ctl);

% it will loop n_loops number of times
for i = 1 : n_loops
    seq.add(coupled);
end
