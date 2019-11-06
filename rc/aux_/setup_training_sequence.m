function seq = setup_training_sequence(ctl, closed_loop, reward_position, distance, back_distance, n_loops)
%%seq = SETUP_TRAINING_SEQUENCE(ctl, closed_loop reward_position, distance, back_distance)
%   Sets up a protocol sequence for training.
%       Inputs:
%               ctl:                controller object
%               closed_loop:        true = closed loop, false = open loop
%               reward_position:    position along the controller
%               distance:           distance to start from reward position
%               back_distance:      amount to move backward before stopping
%       Outputs:
%               seq:                protocol sequence


% setup a single training protocol
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

if closed_loop
    
    prot = Coupled(ctl, config);
    prot.direction = 'forward_and_backward';
else
    
    prot = EncoderOnly(ctl, config);
    prot.direction = 'forward_and_backward';
    prot.integrate_using = 'pc';
end

% setup the protocol sequence
seq = ProtocolSequence(ctl);

% it will loop n_loops number of times
for i = 1 : n_loops
    seq.add(prot);
end
