function [protocolconfig,seq] = einterleaving_PassiveRotationInDarkness(ctl,config,view)
    % Protocol type: passive rotation in darkness
    % central stage - enabled. 
    %       S+ trial, high max speed. 
    %       S- trial, low max speed.
    %       S+ & S- trials are of same speed peakwidth
    % outer stage   - disabled
    % vis_stim      - disabled. 

    fullpath = mfilename('fullpath');
    [~,protocol_id.name] = fileparts(fullpath);
    enableRotation = true;
    enableVisStim = false;
    % config parameters to pass to the protocols
    % Here LickDetect trigger appears at rotation velosity peak time, lasts till rotation ends
    protocolconfig.lick_detect.enable                   = true;     
    protocolconfig.lick_detect.lick_threshold           = [2.0 4.0];
    protocolconfig.lick_detect.n_windows                = 25;      
    protocolconfig.lick_detect.window_size_ms           = 200;
    protocolconfig.lick_detect.n_consecutive_windows    = 1;
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
    protocol_id.s_plusL80         = 1;    % high max speed
    protocol_id.s_plusR80         = 2;
    protocol_id.s_plusL70         = 3;
    protocol_id.s_plusR70         = 4;
    protocol_id.s_plusL60         = 5;
    protocol_id.s_plusR60         = 6;
    protocol_id.s_plusL50         = 7;
    protocol_id.s_plusR50         = 8;
    protocol_id.s_plusL40         = 9;
    protocol_id.s_plusR40         = 10;
    protocol_id.s_plusL30         = 11;
    protocol_id.s_plusR30         = 12;
    protocol_id.s_plusL20         = 13;
    protocol_id.s_plusR20         = 14;
    protocol_id.s_minusL        = 15;    % low max speed
    protocol_id.s_minusR        = 16;
    
    % number of blocks
    n_blocks = 1;
    
    % number of trials in each block
    n_trials = [1 1  1 1  1 1  1 1  1 1  1 1  1 1  1 1];

    protocolconfig.reward.duration = floor(config.reward.interleavingduration/(sum(n_trials(1:14))*n_blocks));
    
    trial_order = [protocol_id.s_plusL80*ones(n_trials(protocol_id.s_plusL80), n_blocks); protocol_id.s_plusR80*ones(n_trials(protocol_id.s_plusR80), n_blocks); ...
        protocol_id.s_plusL70*ones(n_trials(protocol_id.s_plusL70), n_blocks); protocol_id.s_plusR70*ones(n_trials(protocol_id.s_plusR70), n_blocks); ...
        protocol_id.s_plusL60*ones(n_trials(protocol_id.s_plusL60), n_blocks); protocol_id.s_plusR60*ones(n_trials(protocol_id.s_plusR60), n_blocks); ...
        protocol_id.s_plusL50*ones(n_trials(protocol_id.s_plusL50), n_blocks); protocol_id.s_plusR50*ones(n_trials(protocol_id.s_plusR60), n_blocks); ...
        protocol_id.s_plusL40*ones(n_trials(protocol_id.s_plusL40), n_blocks); protocol_id.s_plusR40*ones(n_trials(protocol_id.s_plusR40), n_blocks); ...
        protocol_id.s_plusL30*ones(n_trials(protocol_id.s_plusL30), n_blocks); protocol_id.s_plusR30*ones(n_trials(protocol_id.s_plusR30), n_blocks); ...
        protocol_id.s_plusL20*ones(n_trials(protocol_id.s_plusL20), n_blocks); protocol_id.s_plusR20*ones(n_trials(protocol_id.s_plusR20), n_blocks); ...
        protocol_id.s_minusL*ones(n_trials(protocol_id.s_minusL), n_blocks); protocol_id.s_minusR*ones(n_trials(protocol_id.s_minusR), n_blocks);];
    for i = 1 : n_blocks
        I = randperm(sum([n_trials(protocol_id.s_plusL80),n_trials(protocol_id.s_plusR80),n_trials(protocol_id.s_plusL70),n_trials(protocol_id.s_plusR70),n_trials(protocol_id.s_plusL60),n_trials(protocol_id.s_plusR60),n_trials(protocol_id.s_plusL50),n_trials(protocol_id.s_plusR60),...
            n_trials(protocol_id.s_plusL40),n_trials(protocol_id.s_plusR40),n_trials(protocol_id.s_plusL30),n_trials(protocol_id.s_plusR30),n_trials(protocol_id.s_plusL20),n_trials(protocol_id.s_plusR20),n_trials(protocol_id.s_minusL),n_trials(protocol_id.s_minusR)]));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);


    %% velocity array generator
    distance = 90;
    duration = 30;
    vmax_splus = [80 70 60 50 40 30 20];
    vmax_sminus = 10;
    peakwidth_splus = 2;
    peakwidth_sminus = 2;
    
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol_id.s_plusL80
            
            trial.trial.stimulus_type = 's_plusL80';
            trial.trial.stimulus_typeid = 1;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(1); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(1); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 1;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR80
            
            trial.trial.stimulus_type = 's_plusR80';
            trial.trial.stimulus_typeid = 2;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(1); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(1); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 2;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

         elseif trial_order(i) == protocol_id.s_plusL70
            
            trial.trial.stimulus_type = 's_plusL70';
            trial.trial.stimulus_typeid = 3;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(2); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(2); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 3;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR70
            
            trial.trial.stimulus_type = 's_plusR70';
            trial.trial.stimulus_typeid = 4;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(2); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(2); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 4;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusL60
            
            trial.trial.stimulus_type = 's_plusL60';
            trial.trial.stimulus_typeid = 5;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(3); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(3); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 5;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR60
            
            trial.trial.stimulus_type = 's_plusR60';
            trial.trial.stimulus_typeid = 6;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(3); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(3); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 6;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusL50
            
            trial.trial.stimulus_type = 's_plusL50';
            trial.trial.stimulus_typeid = 7;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(4); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(4); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 7;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR50
            
            trial.trial.stimulus_type = 's_plusR50';
            trial.trial.stimulus_typeid = 8;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(4); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(4); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 8;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol_id.s_plusL40
            
            trial.trial.stimulus_type = 's_plusL40';
            trial.trial.stimulus_typeid = 9;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(5); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(5); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 9;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR40
            
            trial.trial.stimulus_type = 's_plusR40';
            trial.trial.stimulus_typeid = 10;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(5); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(5); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 10;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol_id.s_plusL30
            
            trial.trial.stimulus_type = 's_plusL30';
            trial.trial.stimulus_typeid = 11;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(6); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(6); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 11;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR30
            
            trial.trial.stimulus_type = 's_plusR30';
            trial.trial.stimulus_typeid = 12;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(6); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(6); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 12;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol_id.s_plusL20
            
            trial.trial.stimulus_type = 's_plusL20';
            trial.trial.stimulus_typeid = 13;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_splus(7); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_splus(7); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;

            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 13;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_plusR20
            
            trial.trial.stimulus_type = 's_plusR20';
            trial.trial.stimulus_typeid = 14;
            trial.trial.enable_reward = true;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_splus(7); 
            trial.stage.central.peakwidth = peakwidth_splus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_splus(7); 
            trial.stage.outer.peakwidth = peakwidth_splus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 14;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol_id.s_minusL

            trial.trial.stimulus_type = 's_minusL';
            trial.trial.stimulus_typeid = 15;
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = -distance;
            trial.stage.central.max_vel = vmax_sminus; 
            trial.stage.central.peakwidth = peakwidth_sminus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_sminus; 
            trial.stage.outer.peakwidth = peakwidth_sminus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 15;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol_id.s_minusR

            trial.trial.stimulus_type = 's_minusR';
            trial.trial.stimulus_typeid = 16;
            trial.trial.enable_reward = false;
            
            trial.stage.enable_motion = enableRotation;
            trial.stage.motion_time = duration;
            trial.stage.central.enable = true;
            trial.stage.central.distance = distance;
            trial.stage.central.max_vel = vmax_sminus; 
            trial.stage.central.peakwidth = peakwidth_sminus;
            trial.stage.central.mean_vel = abs(trial.stage.central.distance)/trial.stage.motion_time;
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = distance;
            trial.stage.outer.max_vel = vmax_sminus; 
            trial.stage.outer.peakwidth = peakwidth_sminus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 16;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end