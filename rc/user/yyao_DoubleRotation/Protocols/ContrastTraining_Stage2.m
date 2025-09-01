function [protocolconfig,seq] = ContrastTraining_Stage2(ctl,config,view)
    % Protocol type: visual slimuli with fixed contrast difference (S+) or same contrast (S-). 10 S+ 10 S- in psudorandom order
    % central stage - enabled. 
    %       S+ trial, fixed contrast difference. 
    %       S- trial, contrast same.
    % outer stage   - disabled
    % vis_stim      - enabled. 

    fullpath = mfilename('fullpath');
    [~,protocol_id.name] = fileparts(fullpath);
    enableRotation = true;
    enableVisStim = true;
    % config parameters to pass to the protocols
    % Here LickDetect trigger appears at rotation velosity peak time, lasts till rotation ends
    protocolconfig.lick_detect.enable                   = true;     
    protocolconfig.lick_detect.lick_threshold           = [2.0 4.0];
    protocolconfig.lick_detect.n_windows                = 23;      
    protocolconfig.lick_detect.window_size_ms           = 200;
    protocolconfig.lick_detect.n_consecutive_windows    = 1;
    protocolconfig.lick_detect.n_lick_windows           = protocolconfig.lick_detect.n_consecutive_windows;
    protocolconfig.lick_detect.detection_trigger_type   = 1;
    protocolconfig.lick_detect.delay                    = 0.5;       % delay of LickDetect trigger from TrialStart (in sec)
    protocolconfig.enable_vis_stim = enableVisStim;
    
    % create the protocol sequence
    seq = VisualContrast(ctl,config,view);
    
    %%
    % restart random number generator
    rng('shuffle');

    % list of protocols
    protocol_id.s_plusL         = 1;    % fixed contrast difference: L 100% R 50%, L 50% R 100%
    protocol_id.s_plusR         = 2;
    protocol_id.s_minus        = 3;    % contrast same: L 50% R 50%
    
    % number of blocks
    n_blocks = 5;
    
    % number of trials in each block
    n_s_plusL_trials    = 1;
    n_s_plusR_trials    = 1;
    n_s_minus_trials   = 2;
    
    protocolconfig.reward.duration = floor(config.reward.sminus1duration/((n_s_plusL_trials+n_s_plusR_trials)*n_blocks));

    trial_order = [ones(n_s_plusL_trials, n_blocks); 2*ones(n_s_plusR_trials, n_blocks); 3*ones(n_s_minus_trials, n_blocks)];
    for i = 1 : n_blocks
        I = randperm(sum([n_s_plusL_trials,n_s_plusR_trials,n_s_minus_trials]));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);

    
    %% velocity array generator
    distance = 0;
    duration = 3;
    vmax_splus = 0;
    vmax_sminus = 0;
    peakwidth_splus = 2;
    peakwidth_sminus = 2;
    latency_range = [1 3];
    
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol_id.s_plusL
            
            trial.trial.stimulus_type = 's_plusL';
            trial.trial.stimulus_typeid = 1;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus; 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus; 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 1;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR
            
            trial.trial.stimulus_type = 's_plusR';
            trial.trial.stimulus_typeid = 2;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus; 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus; 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 2;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minus

            trial.trial.stimulus_type = 's_minus';
            trial.trial.stimulus_typeid = 3;
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_sminus; 
            trial.stage.central.peakwidth = peakwidth_sminus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = true;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_sminus; 
            trial.stage.outer.peakwidth = peakwidth_sminus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 3;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end