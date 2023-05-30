function [protocolconfig,seq] = VisualOnly_test_02(ctl,config,view)
    % Protocol type: visual stimuli only
    % central stage - disabled. 
    % outer stage   - disabled
    % vis_stim      - enabled

    protocol_id.name = 'VisualOnly_test_02';                
    enableRotation = false;
    enableVisStim = true;
    % config parameters to pass to the protocols
    % Here LickDetect trigger appears at rotation velosity peak time, lasts till rotation ends
    protocolconfig.lick_detect.enable                   = true;     
    protocolconfig.lick_detect.lick_threshold           = 1;
    protocolconfig.lick_detect.n_windows                = 60;      
    protocolconfig.lick_detect.window_size_ms           = 250;
    protocolconfig.lick_detect.n_consecutive_windows    = 2;
    protocolconfig.lick_detect.n_lick_windows           = protocolconfig.lick_detect.n_consecutive_windows;        
    protocolconfig.lick_detect.detection_trigger_type   = 1;
    protocolconfig.lick_detect.delay                    = 15;       % delay of LickDetect trigger from TrialStart (in sec)
    protocolconfig.enable_vis_stim = enableVisStim;
    
    % create the protocol sequence
    seq = ProtocolSequence_DoubleRotation(ctl,config,view);
    
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
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = [];
            trial.stage.central.enable = false;
            trial.stage.central.distance = [];
            trial.stage.central.max_vel = []; 
            trial.stage.central.mean_vel = [];
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = [];
            trial.stage.outer.max_vel = []; 
            trial.stage.outer.mean_vel = [];
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 1;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR
            
            trial.trial.stimulus_type = 's_plusR';
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = [];
            trial.stage.central.enable = false;
            trial.stage.central.distance = [];
            trial.stage.central.max_vel = []; 
            trial.stage.central.mean_vel = [];
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = [];
            trial.stage.outer.max_vel = []; 
            trial.stage.outer.mean_vel = [];
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 2;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusL

            trial.trial.stimulus_type = 's_minusL';
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = [];
            trial.stage.central.enable = false;
            trial.stage.central.distance = [];
            trial.stage.central.max_vel = []; 
            trial.stage.central.mean_vel = [];
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = [];
            trial.stage.outer.max_vel = []; 
            trial.stage.outer.mean_vel = [];
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 3;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusR

            trial.trial.stimulus_type = 's_minusR';
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = [];
            trial.stage.central.enable = false;
            trial.stage.central.distance = [];
            trial.stage.central.max_vel = []; 
            trial.stage.central.mean_vel = [];
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = [];
            trial.stage.outer.max_vel = []; 
            trial.stage.outer.mean_vel = [];
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 4;
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end