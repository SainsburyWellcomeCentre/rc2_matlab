function [protocolconfig,seq] = ContrastTraining_Stage3(ctl,config,view)
    % Protocol type: visual slimuli with various contrast difference (S+) or same contrast (S-). 10 S+ 10 S- in psudorandom order
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

    protocol.labels = {'s_plusL_75_25','s_plusR_25_75','s_plusL_60_40','s_plusR_40_60','s_plusL_55_45','s_plusR_45_55','s_minus_50'};
    for i = 1:length(protocol.labels)
        protocol.id(i) = i;
    end
    
    % number of blocks
    protocol.n_blocks = 2;
    
    % number of trials in each block
    protocol.n_trials = [1 1  1 1  1 1  6];

    protocolconfig.reward.duration = floor(config.reward.sminus2duration/(sum(protocol.n_trials(1:end))*protocol.n_blocks));
    
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
    duration = 3;
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
            trial.vis.vis_stim_lable = 7;
            trial.vis.latency = (latency_range(2)-latency_range(1)).*rand(1,1)+latency_range(1);

%             trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            trial.waveform = zeros(duration*config.nidaq.rate,2);
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end