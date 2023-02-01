function seq = Agatha_04(ctl)

    protocol_id.name = 'Agatha_04';                         % 根据protocol_id配置lick_detect参数
    
    % config parameters to pass to the protocols
    config.lick_detect.enable           = true;   % 使舔食检测模块可用
    config.lick_detect.lick_threshold       = 1;
    config.lick_detect.n_windows        = 80;
    config.lick_detect.window_size_ms   = 50;
    config.lick_detect.n_lick_windows   = 1;
    config.lick_detect.n_consecutive_windows = 1; %modified by A on 23/8; was 4
    config.lick_detect.detection_trigger_type = 1;
    
    % create the protocol sequence
    seq = ProtocolSequence_DoubleRotation(ctl);
    
    %%
    % restart random number generator
    rng(1)

    % list of protocols
    protocol_id.s_plus          = 1;
    protocol_id.s_minusL        = 2;
    protocol_id.s_minusR        = 3;
    
    % number of blocks
    n_blocks = 5;
    
    % number of trials in each block
    n_s_plus_trials     = 2;
    n_s_minusL_trials   = 1;
    n_s_minusR_trials   = 1;
    
    trial_order = [ones(n_s_plus_trials, n_blocks); 2*ones(n_s_minusL_trials, n_blocks); 3*ones(n_s_minusR_trials, n_blocks)];
    for i = 1 : n_blocks
        I = randperm(sum([n_s_plus_trials,n_s_minusL_trials,n_s_minusR_trials]));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);
    
    %%
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol_id.s_plus

            vis.stimulus_type = 's_plus';
            vis.vis_stim_type = 1;
            vis.enable_reward = true;
    %         vis.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(vis);

        elseif trial_order(i) == protocol_id.s_minusL

            vis.stimulus_type = 's_minus';
            vis.vis_stim_type = 2;
            vis.enable_reward = false;
    %         vis.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(vis);

        elseif trial_order(i) == protocol_id.s_minusR

            vis.stimulus_type = 's_minus';
            vis.vis_stim_type = 3;
            vis.enable_reward = false;
    %         vis.enable_vis_stim = true;

            % add protocol to the sequence
            seq.add(vis);

        end
    end
end