function seq = setup_training_sequence(ctl, closed_loop, reward_position, distance, back_distance, n_loops, forward_only)
    % Sets up a protocol sequence for training. This is a standard sequence so contained in the main program.
    %
    % :param ctl: A :class:`rc.main.RC2Controller` object.
    % :param closed_loop: Boolean specifying whether to run as closed-loop (true) or open-loop (false).
    % :param reward_position: Position along the linear stage at which to stop trial and deliver reward.
    % :param distance: Distance to start from reward position.
    % :param back_distance: Amount to move backward before stopping trial.
    % :param n_loops: The number of loops of the protocol to set up.
    % :param forward_only: Boolean specifying whether we should only allow forward movement (true) or backward movement as well (false).
    % :return: Protocol sequence of :class:`rc.prot.ProtocolSequence`.

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
