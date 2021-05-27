function seq = setup_training_sequence(ctl, closed_loop, reward_position, distance, back_distance, n_loops, forward_only)
%%seq = SETUP_TRAINING_SEQUENCE(ctl, closed_loop reward_position, distance, back_distance, n_loops, forward_only)
%   Sets up a protocol sequence for training. This is a standard sequence
%   so contained in the main program.
%       Inputs:
%               ctl:                controller object
%               closed_loop:        true = closed loop, false = open loop
%               reward_position:    position along the controller
%               distance:           distance to start from reward position
%               back_distance:      amount to move backward before stopping
%               n_loops:            the number of loops of the protocol to
%                                   setup
%               forward_only:       true = only allow forward movement
%                                   false = allow backward movement as well
%       Outputs:
%               seq:                protocol sequence


% setup a single training protocol
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% during training don't randomize the reward
ctl.reward.randomize = false;

if closed_loop
    
    prot = Coupled(ctl, config);
else
    
    prot = EncoderOnly(ctl, config);
    prot.integrate_using = 'pc';
end

if forward_only
    prot.direction = 'forward_only';
else
    prot.direction = 'forward_and_backward';
end

% setup the protocol sequence
seq = ProtocolSequence(ctl);

% it will loop n_loops number of times
for i = 1 : n_loops
    seq.add(prot);
end
