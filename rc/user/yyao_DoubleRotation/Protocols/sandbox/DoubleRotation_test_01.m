function [protocolconfig,seq] = DoubleRotation_test_01(ctl,view)
    % Protocol type: passive rotation with visual stimuli
    % central stage - enabled. 
    %       S+ trial, high max speed. 
    %       S- trial, low max speed.
    % outer stage   - disabled
    % vis_stim      - enabled. 

    protocol_id.name = 'DoubleRotation_test_01';               
    
    % config parameters to pass to the protocols
    protocolconfig.lick_detect.enable                   = true;     
    protocolconfig.lick_detect.lick_threshold           = 1;
    protocolconfig.lick_detect.n_windows                = 80;
    protocolconfig.lick_detect.window_size_ms           = 50;
    protocolconfig.lick_detect.n_lick_windows           = 1;
    protocolconfig.lick_detect.n_consecutive_windows    = 4;        % modified by A on 23/8; was 4
    protocolconfig.lick_detect.detection_trigger_type   = 1;
    protocolconfig.enable_vis_stim = true;
    
    % create the protocol sequence
    seq = ProtocolSequence_DoubleRotation(ctl,view);
    
    %%
    % restart random number generator
    rng('shuffle');

    % list of protocols
    protocol_id.s_plusL         = 1;    % high max speed
    protocol_id.s_plusR         = 2;
    protocol_id.s_minusL        = 3;    % low max speed
    protocol_id.s_minusR        = 4;
    
    % number of blocks
    n_blocks = 1;
    
    % number of trials in each block
    n_s_plusL_trials    = 1;
    n_s_plusR_trials    = 1;
    n_s_minusL_trials   = 1;
    n_s_minusR_trials   = 1;
    
    trial_order = [ones(n_s_plusL_trials, n_blocks); 2*ones(n_s_plusR_trials, n_blocks); 3*ones(n_s_minusL_trials, n_blocks); 4*ones(n_s_minusR_trials, n_blocks)];
    for i = 1 : n_blocks
        I = randperm(sum([n_s_plusL_trials,n_s_plusR_trials,n_s_minusL_trials,n_s_minusR_trials]));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);

    % velocity array generator

    
    %%
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol_id.s_plusL
            
            trial.trial.stimulus_type = 's_plusL';
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = true;
            trial.stage.motion_time = 15;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -90;
            trial.stage.central.max_vel = 40; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = -90;
            trial.stage.outer.max_vel = 40; 
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = true;
            trial.vis.vis_stim_lable = 1;

            trial.waveform = voltagewaveform_generator_synchronous(trial.stage, 10000);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR
            
            trial.trial.stimulus_type = 's_plusR';
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = true;
            trial.stage.motion_time = 15;
            trial.stage.central.enable = true;
            trial.stage.central.distance = 90;
            trial.stage.central.max_vel = 40; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = 90;
            trial.stage.outer.max_vel = 40; 
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = true;
            trial.vis.vis_stim_lable = 2;

            trial.waveform = voltagewaveform_generator_synchronous(trial.stage, 10000);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusL

            trial.trial.stimulus_type = 's_minusL';
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = true;
            trial.stage.motion_time = 15;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -90;
            trial.stage.central.max_vel = 10; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = -90;
            trial.stage.outer.max_vel = 10; 
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = true;
            trial.vis.vis_stim_lable = 3;

            trial.waveform = voltagewaveform_generator_synchronous(trial.stage, 10000);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusR

            trial.trial.stimulus_type = 's_minusR';
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = true;
            trial.stage.motion_time = 15;
            trial.stage.central.enable = true;
            trial.stage.central.distance = 90;
            trial.stage.central.max_vel = 10; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = 90;
            trial.stage.outer.max_vel = 10; 
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = true;
            trial.vis.vis_stim_lable = 4;

            trial.waveform = voltagewaveform_generator_synchronous(trial.stage, 10000);
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end