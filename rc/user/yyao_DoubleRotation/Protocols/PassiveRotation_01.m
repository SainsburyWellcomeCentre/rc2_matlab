function seq = PassiveRotation_01(ctl)
    % Protocol type: passive rotation in darkness
    % central stage - enabled. 
    %       S+ trial, high max speed. 
    %       S- trial, low max speed.
    % outer stage   - disabled
    % vis_stim      - disabled

    protocol_id.name = 'PassiveRotation_01';                % 根据protocol_id配置lick_detect参数
    
    % config parameters to pass to the protocols
    config.lick_detect.enable                   = true;     % 使舔食检测模块可用
    config.lick_detect.lick_threshold           = 1;
    config.lick_detect.n_windows                = 80;
    config.lick_detect.window_size_ms           = 50;
    config.lick_detect.n_lick_windows           = 1;
    config.lick_detect.n_consecutive_windows    = 4;        % modified by A on 23/8; was 4
    config.lick_detect.detection_trigger_type   = 1;
    
    % create the protocol sequence
    seq = ProtocolSequence_DoubleRotation(ctl);
    
    %%
    % restart random number generator
    rng(1)

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
            
            trial.stage.motion_time = 32.2;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -90;
            trial.stage.central.max_vel = 40; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = 0;
            trial.stage.outer.max_vel = 0; 
            trial.stage.outer.mean_vel = 0;

            trial.vis.enable_vis_stim = false;
            trial.vis.vis_stim_type = 1;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR
            
            trial.trial.stimulus_type = 's_plusR';
            trial.trial.enable_reward = true;
            
            trial.stage.motion_time = 32.2;
            trial.stage.central.enable = true;
            trial.stage.central.distance = 90;
            trial.stage.central.max_vel = 40; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = 0;
            trial.stage.outer.max_vel = 0; 
            trial.stage.outer.mean_vel = 0;
            
            trial.vis.enable_vis_stim = false;
            trial.vis.vis_stim_type = 2;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusL

            trial.trial.stimulus_type = 's_minusL';
            trial.trial.enable_reward = false;
            
            trial.stage.motion_time = 32.2;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -90;
            trial.stage.central.max_vel = 10; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = 0;
            trial.stage.outer.max_vel = 0; 
            trial.stage.outer.mean_vel = 0;
            
            trial.vis.enable_vis_stim = false;
            trial.vis.vis_stim_type = 3;
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusR

            trial.trial.stimulus_type = 's_minusR';
            trial.trial.enable_reward = false;
            
            trial.stage.motion_time = 32.2;
            trial.stage.central.enable = true;
            trial.stage.central.distance = 90;
            trial.stage.central.max_vel = 10; 
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = 0;
            trial.stage.outer.max_vel = 0; 
            trial.stage.outer.mean_vel = 0;
            
            trial.vis.enable_vis_stim = false;
            trial.vis.vis_stim_type = 4;
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end