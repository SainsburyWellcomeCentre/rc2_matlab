function [protocolconfig,seq] = ContrastExperiment(ctl,config,view)
    % Protocol type: visual slimuli with fixed contrast difference (S+) or same contrast (S-) in various brightness. 10 S+ 10 S- in psudorandom order
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

    protocol.labels = {'s_plusL_1_7','s_plusR_1_7','s_plusL_1_6','s_plusR_1_6','s_plusL_1_5','s_plusR_1_5','s_plusL_1_4','s_plusR_1_4','s_plusL_1_3','s_plusR_1_3','s_plusL_1_2','s_plusR_1_2','s_plusL_1_1','s_plusR_1_1',...
        's_plusL_2_7','s_plusR_2_7','s_plusL_2_6','s_plusR_2_6','s_plusL_2_5','s_plusR_2_5','s_plusL_2_4','s_plusR_2_4','s_plusL_2_3','s_plusR_2_3','s_plusL_2_2','s_plusR_2_2','s_plusL_2_1','s_plusR_2_1',...
        's_plusL_3_7','s_plusR_3_7','s_plusL_3_6','s_plusR_3_6','s_plusL_3_5','s_plusR_3_5','s_plusL_3_4','s_plusR_3_4','s_plusL_3_3','s_plusR_3_3','s_plusL_3_2','s_plusR_3_2','s_plusL_3_1','s_plusR_3_1',...
        's_plusL_4_7','s_plusR_4_7','s_plusL_4_6','s_plusR_4_6','s_plusL_4_5','s_plusR_4_5','s_plusL_4_4','s_plusR_4_4','s_plusL_4_3','s_plusR_4_3','s_plusL_4_2','s_plusR_4_2','s_plusL_4_1','s_plusR_4_1',...
        's_plusL_5_7','s_plusR_5_7','s_plusL_5_6','s_plusR_5_6','s_plusL_5_5','s_plusR_5_5','s_plusL_5_4','s_plusR_5_4','s_plusL_5_3','s_plusR_5_3','s_plusL_5_2','s_plusR_5_2','s_plusL_5_1','s_plusR_5_1',...
        's_minus_1','s_minus_2','s_minus_3','s_minus_4','s_minus_5'};
    
    for i = 1:length(protocol.labels)
        protocol.id(i) = i;
    end
    
    % number of blocks
    protocol.n_blocks = 1;
    
    % number of trials in each block
    protocol.n_trials = [1 1  1 1  1 1  1 1  1 1  1 1  1 1 ...
        1 1  1 1  1 1  1 1  1 1  1 1  1 1 ...
        1 1  1 1  1 1  1 1  1 1  1 1  1 1 ...
        1 1  1 1  1 1  1 1  1 1  1 1  1 1 ...
        1 1  1 1  1 1  1 1  1 1  1 1  1 1 ...
        10  10  10  10  10];

    protocolconfig.reward.duration = floor(config.reward.interleavingduration/(sum(protocol.n_trials(1:end))*protocol.n_blocks));
    
    trial_order = [];
    for i = 1:length(protocol.labels)
        trial_order = vertcat(trial_order,protocol.id(i)*ones(protocol.n_trials(i), protocol.n_blocks));
        total_trials(i) = protocol.n_trials(protocol.id(i));
    end
    for i = 1 : protocol.n_blocks
        I = randperm(sum(total_trials));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);

    %% velocity array generator
    distance = 0;
    duration = 5;
    vmax_splus = 0;
    vmax_sminus = 0;
    peakwidth_splus = 2;
    peakwidth_sminus = 2;
    latency_range = [1 3];
    
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol.id(1)
            
            trial.trial.stimulus_type = protocol.labels{1};
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

        elseif trial_order(i) == protocol.id(2)
            
            trial.trial.stimulus_type = protocol.labels{2};
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

        elseif trial_order(i) == protocol.id(3)
            
            trial.trial.stimulus_type = protocol.labels{3};
            trial.trial.stimulus_typeid = 3;
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
            trial.vis.vis_stim_lable = 3;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(4)
            
            trial.trial.stimulus_type = protocol.labels{4};
            trial.trial.stimulus_typeid = 4;
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
            trial.vis.vis_stim_lable = 4;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(5)
            
            trial.trial.stimulus_type = protocol.labels{5};
            trial.trial.stimulus_typeid = 5;
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
            trial.vis.vis_stim_lable = 5;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(6)
            
            trial.trial.stimulus_type = protocol.labels{6};
            trial.trial.stimulus_typeid = 6;
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
            trial.vis.vis_stim_lable = 6;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(7)
            
            trial.trial.stimulus_type = protocol.labels{7};
            trial.trial.stimulus_typeid = 7;
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
            trial.vis.vis_stim_lable = 7;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(8)
            
            trial.trial.stimulus_type = protocol.labels{8};
            trial.trial.stimulus_typeid = 8;
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
            trial.vis.vis_stim_lable = 8;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(9)
            
            trial.trial.stimulus_type = protocol.labels{9};
            trial.trial.stimulus_typeid = 9;
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
            trial.vis.vis_stim_lable = 9;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(10)
            
            trial.trial.stimulus_type = protocol.labels{10};
            trial.trial.stimulus_typeid = 10;
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
            trial.vis.vis_stim_lable = 10;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(11)
            
            trial.trial.stimulus_type = protocol.labels{11};
            trial.trial.stimulus_typeid = 11;
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
            trial.vis.vis_stim_lable = 11;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(12)
            
            trial.trial.stimulus_type = protocol.labels{12};
            trial.trial.stimulus_typeid = 12;
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
            trial.vis.vis_stim_lable = 12;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(13)
            
            trial.trial.stimulus_type = protocol.labels{13};
            trial.trial.stimulus_typeid = 13;
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
            trial.vis.vis_stim_lable = 13;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(14)
            
            trial.trial.stimulus_type = protocol.labels{14};
            trial.trial.stimulus_typeid = 14;
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
            trial.vis.vis_stim_lable = 14;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(15)
            
            trial.trial.stimulus_type = protocol.labels{15};
            trial.trial.stimulus_typeid = 15;
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
            trial.vis.vis_stim_lable = 15;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(16)
            
            trial.trial.stimulus_type = protocol.labels{16};
            trial.trial.stimulus_typeid = 16;
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
            trial.vis.vis_stim_lable = 16;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(17)
            
            trial.trial.stimulus_type = protocol.labels{17};
            trial.trial.stimulus_typeid = 17;
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
            trial.vis.vis_stim_lable = 17;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(18)
            
            trial.trial.stimulus_type = protocol.labels{18};
            trial.trial.stimulus_typeid = 18;
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
            trial.vis.vis_stim_lable = 18;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(19)
            
            trial.trial.stimulus_type = protocol.labels{19};
            trial.trial.stimulus_typeid = 19;
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
            trial.vis.vis_stim_lable = 19;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(20)
            
            trial.trial.stimulus_type = protocol.labels{20};
            trial.trial.stimulus_typeid = 20;
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
            trial.vis.vis_stim_lable = 20;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(21)
            
            trial.trial.stimulus_type = protocol.labels{21};
            trial.trial.stimulus_typeid = 21;
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
            trial.vis.vis_stim_lable = 21;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(22)
            
            trial.trial.stimulus_type = protocol.labels{22};
            trial.trial.stimulus_typeid = 22;
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
            trial.vis.vis_stim_lable = 22;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(23)
            
            trial.trial.stimulus_type = protocol.labels{23};
            trial.trial.stimulus_typeid = 23;
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
            trial.vis.vis_stim_lable = 23;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(24)
            
            trial.trial.stimulus_type = protocol.labels{24};
            trial.trial.stimulus_typeid = 24;
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
            trial.vis.vis_stim_lable = 24;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(25)
            
            trial.trial.stimulus_type = protocol.labels{25};
            trial.trial.stimulus_typeid = 25;
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
            trial.vis.vis_stim_lable = 25;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(26)
            
            trial.trial.stimulus_type = protocol.labels{26};
            trial.trial.stimulus_typeid = 26;
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
            trial.vis.vis_stim_lable = 26;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(27)
            
            trial.trial.stimulus_type = protocol.labels{27};
            trial.trial.stimulus_typeid = 27;
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
            trial.vis.vis_stim_lable = 27;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(28)
            
            trial.trial.stimulus_type = protocol.labels{28};
            trial.trial.stimulus_typeid = 28;
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
            trial.vis.vis_stim_lable = 28;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(29)
            
            trial.trial.stimulus_type = protocol.labels{29};
            trial.trial.stimulus_typeid = 29;
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
            trial.vis.vis_stim_lable = 29;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(30)
            
            trial.trial.stimulus_type = protocol.labels{30};
            trial.trial.stimulus_typeid = 30;
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
            trial.vis.vis_stim_lable = 30;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(31)
            
            trial.trial.stimulus_type = protocol.labels{31};
            trial.trial.stimulus_typeid = 31;
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
            trial.vis.vis_stim_lable = 31;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(32)
            
            trial.trial.stimulus_type = protocol.labels{32};
            trial.trial.stimulus_typeid = 32;
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
            trial.vis.vis_stim_lable = 32;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(33)
            
            trial.trial.stimulus_type = protocol.labels{33};
            trial.trial.stimulus_typeid = 33;
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
            trial.vis.vis_stim_lable = 33;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(34)
            
            trial.trial.stimulus_type = protocol.labels{34};
            trial.trial.stimulus_typeid = 34;
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
            trial.vis.vis_stim_lable = 34;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(35)
            
            trial.trial.stimulus_type = protocol.labels{35};
            trial.trial.stimulus_typeid = 35;
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
            trial.vis.vis_stim_lable = 35;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(36)
            
            trial.trial.stimulus_type = protocol.labels{36};
            trial.trial.stimulus_typeid = 36;
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
            trial.vis.vis_stim_lable = 36;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(37)
            
            trial.trial.stimulus_type = protocol.labels{37};
            trial.trial.stimulus_typeid = 37;
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
            trial.vis.vis_stim_lable = 37;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(38)
            
            trial.trial.stimulus_type = protocol.labels{38};
            trial.trial.stimulus_typeid = 38;
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
            trial.vis.vis_stim_lable = 38;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(39)
            
            trial.trial.stimulus_type = protocol.labels{39};
            trial.trial.stimulus_typeid = 39;
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
            trial.vis.vis_stim_lable = 39;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(40)
            
            trial.trial.stimulus_type = protocol.labels{40};
            trial.trial.stimulus_typeid = 40;
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
            trial.vis.vis_stim_lable = 40;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(41)
            
            trial.trial.stimulus_type = protocol.labels{41};
            trial.trial.stimulus_typeid = 41;
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
            trial.vis.vis_stim_lable = 41;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(42)
            
            trial.trial.stimulus_type = protocol.labels{42};
            trial.trial.stimulus_typeid = 42;
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
            trial.vis.vis_stim_lable = 42;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(43)
            
            trial.trial.stimulus_type = protocol.labels{43};
            trial.trial.stimulus_typeid = 43;
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
            trial.vis.vis_stim_lable = 43;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(44)
            
            trial.trial.stimulus_type = protocol.labels{44};
            trial.trial.stimulus_typeid = 44;
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
            trial.vis.vis_stim_lable = 44;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(45)
            
            trial.trial.stimulus_type = protocol.labels{45};
            trial.trial.stimulus_typeid = 45;
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
            trial.vis.vis_stim_lable = 45;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(46)
            
            trial.trial.stimulus_type = protocol.labels{46};
            trial.trial.stimulus_typeid = 46;
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
            trial.vis.vis_stim_lable = 46;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(47)
            
            trial.trial.stimulus_type = protocol.labels{47};
            trial.trial.stimulus_typeid = 47;
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
            trial.vis.vis_stim_lable = 47;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(48)
            
            trial.trial.stimulus_type = protocol.labels{48};
            trial.trial.stimulus_typeid = 48;
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
            trial.vis.vis_stim_lable = 48;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(49)
            
            trial.trial.stimulus_type = protocol.labels{49};
            trial.trial.stimulus_typeid = 49;
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
            trial.vis.vis_stim_lable = 49;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(50)
            
            trial.trial.stimulus_type = protocol.labels{50};
            trial.trial.stimulus_typeid = 50;
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
            trial.vis.vis_stim_lable = 50;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(51)
            
            trial.trial.stimulus_type = protocol.labels{51};
            trial.trial.stimulus_typeid = 51;
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
            trial.vis.vis_stim_lable = 51;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(52)
            
            trial.trial.stimulus_type = protocol.labels{52};
            trial.trial.stimulus_typeid = 52;
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
            trial.vis.vis_stim_lable = 52;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(53)
            
            trial.trial.stimulus_type = protocol.labels{53};
            trial.trial.stimulus_typeid = 53;
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
            trial.vis.vis_stim_lable = 53;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(54)
            
            trial.trial.stimulus_type = protocol.labels{54};
            trial.trial.stimulus_typeid = 54;
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
            trial.vis.vis_stim_lable = 54;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(55)
            
            trial.trial.stimulus_type = protocol.labels{55};
            trial.trial.stimulus_typeid = 55;
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
            trial.vis.vis_stim_lable = 55;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(56)
            
            trial.trial.stimulus_type = protocol.labels{56};
            trial.trial.stimulus_typeid = 56;
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
            trial.vis.vis_stim_lable = 56;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(57)
            
            trial.trial.stimulus_type = protocol.labels{57};
            trial.trial.stimulus_typeid = 57;
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
            trial.vis.vis_stim_lable = 57;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(58)
            
            trial.trial.stimulus_type = protocol.labels{58};
            trial.trial.stimulus_typeid = 58;
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
            trial.vis.vis_stim_lable = 58;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(59)
            
            trial.trial.stimulus_type = protocol.labels{59};
            trial.trial.stimulus_typeid = 59;
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
            trial.vis.vis_stim_lable = 59;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(60)
            
            trial.trial.stimulus_type = protocol.labels{60};
            trial.trial.stimulus_typeid = 60;
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
            trial.vis.vis_stim_lable = 60;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(61)
            
            trial.trial.stimulus_type = protocol.labels{61};
            trial.trial.stimulus_typeid = 61;
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
            trial.vis.vis_stim_lable = 61;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(62)
            
            trial.trial.stimulus_type = protocol.labels{62};
            trial.trial.stimulus_typeid = 62;
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
            trial.vis.vis_stim_lable = 62;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);
        
        elseif trial_order(i) == protocol.id(63)
            
            trial.trial.stimulus_type = protocol.labels{63};
            trial.trial.stimulus_typeid = 63;
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
            trial.vis.vis_stim_lable = 63;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(64)
            
            trial.trial.stimulus_type = protocol.labels{64};
            trial.trial.stimulus_typeid = 64;
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
            trial.vis.vis_stim_lable = 64;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(65)
            
            trial.trial.stimulus_type = protocol.labels{65};
            trial.trial.stimulus_typeid = 65;
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
            trial.vis.vis_stim_lable = 65;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(66)
            
            trial.trial.stimulus_type = protocol.labels{66};
            trial.trial.stimulus_typeid = 66;
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
            trial.vis.vis_stim_lable = 66;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(67)
            
            trial.trial.stimulus_type = protocol.labels{67};
            trial.trial.stimulus_typeid = 67;
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
            trial.vis.vis_stim_lable = 67;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(68)
            
            trial.trial.stimulus_type = protocol.labels{68};
            trial.trial.stimulus_typeid = 68;
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
            trial.vis.vis_stim_lable = 68;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(69)
            
            trial.trial.stimulus_type = protocol.labels{69};
            trial.trial.stimulus_typeid = 69;
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
            trial.vis.vis_stim_lable = 69;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(70)
            
            trial.trial.stimulus_type = protocol.labels{70};
            trial.trial.stimulus_typeid = 70;
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
            trial.vis.vis_stim_lable = 70;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        


        elseif trial_order(i) == protocol.id(end-4)

            trial.trial.stimulus_type = protocol.labels{end-4};
            trial.trial.stimulus_typeid = length(protocol.labels)-4;
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
            trial.vis.vis_stim_lable = 71;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(end-3)

            trial.trial.stimulus_type = protocol.labels{end-3};
            trial.trial.stimulus_typeid = length(protocol.labels)-3;
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
            trial.vis.vis_stim_lable = 72;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(end-2)

            trial.trial.stimulus_type = protocol.labels{end-2};
            trial.trial.stimulus_typeid = length(protocol.labels)-2;
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
            trial.vis.vis_stim_lable = 73;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(end-1)

            trial.trial.stimulus_type = protocol.labels{end-1};
            trial.trial.stimulus_typeid = length(protocol.labels)-1;
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
            trial.vis.vis_stim_lable = 74;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(end)

            trial.trial.stimulus_type = protocol.labels{end};
            trial.trial.stimulus_typeid = length(protocol.labels);
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
            trial.vis.vis_stim_lable = 75;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        
        end
    end
end