function seq = passive_protocol_3p_vest_darkness(ctl)
    %% Load sequence
    % "trial_order" is a 3xN matrix of protocol indices. Each column is a batch
    % of trials specifying a particular order (1-4 in some order that makes sense).
    % "protocol_id" is a structure which relates the numbers in "trial_order"
    % to the protocol by name:
    %       vest_with_flow
    %       vest_darkness
    %       visual_flow
    % fnames is the locations of .bin files containing relevant waveforms

    load('passive_protocol_sequence_3p_darkness_only.mat', 'trial_order', 'protocol_id', 'fnames');
    
    %% Global parameters
    % create the protocol sequence
    seq = ProtocolSequence(ctl);

    % we will randomize the rewards
    seq.randomize_reward = true;
    
    %% Build trial structure
    for i = 1:length(trial_order)
        if trial_order(i) == protocol_id.vest_with_flow    
            % setup the locovest replay protocol
            vest = StageOnly(ctl, config);

            % mouse must initiate trial
            vest.initiate_trial = false;

            % increase start dwell time slightly
            vest.start_dwell_time = 3;

            vest.wave_fname = fnames{i};

            % enable vis stim
            vest.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(vest);
            
        elseif trial_order(i) == protocol_id.visual_flow
            % setup the locovest protocol
            replay = ReplayOnly(ctl, config);

            % mouse must initiate trial
            replay.initiate_trial = false;

            % increase start dwell time slightly
            replay.start_dwell_time = 3;

            replay.wave_fname = fnames{i};

            % enable vis stim
            replay.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(replay);
            
        elseif trial_order(i) == protocol_id.vest_darkness
            % setup the locovest replay protocol
            vest = StageOnly(ctl, config);
        
            % mouse must initiate trial
            vest.initiate_trial = false;
        
            % increase start dwell time slightly
            vest.start_dwell_time = 3;
        
            vest.wave_fname = fnames{i};
        
            % disable vis stim
            vest.enable_vis_stim = false;
        
            % add protocol to the sequence
            seq.add(vest);
            
        end
    end
end

