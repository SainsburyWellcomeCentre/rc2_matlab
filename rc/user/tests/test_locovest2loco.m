function seq = test_locovest2loco(ctl)

% parameters of the test
n_trials            = 5;
reward_position     = 250;
distance            = 1200;
back_distance       = 5;
switch_pos          = 850
jitter              = 100;

% create auxiliary structure
config.stage.start_pos = reward_position + distance;
config.stage.back_limit = config.stage.start_pos + back_distance;
config.stage.forward_limit = reward_position;

% setup the protocol sequence
seq = ProtocolSequence(ctl);

% iterate over saved waveforms
current_saved_waveform = 0;

% it will loop n_loops number of times
for i = 1 : n_trials
    locovest = LocoVest2Loco(ctl, config);
    locovest.switch_pos = switch_pos + (2*jitter - 1)*rand;
    seq.add(locovest);
end