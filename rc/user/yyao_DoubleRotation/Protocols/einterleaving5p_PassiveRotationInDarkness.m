function [protocolconfig,seq] = einterleaving5p_PassiveRotationInDarkness(ctl,config,view)
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
    protocol.labels = {'s_plusL70','s_plusR70','s_plusL55','s_plusR55','s_plusL40','s_plusR40','s_plusL25','s_plusR25','s_plusL10','s_plusR10','s_minusL','s_minusR'};
    for i = 1:length(protocol.labels)
%         eval(['protocol.id.' protocol.labels{i} '=i;']);
        protocol.id(i) = i;
    end
%     protocol_id.s_plusL70         = 1;    % high max speed
%     protocol_id.s_plusR70         = 2;
%     protocol_id.s_plusL55         = 3;
%     protocol_id.s_plusR55         = 4;
%     protocol_id.s_plusL40         = 5;
%     protocol_id.s_plusR40         = 6;
%     protocol_id.s_plusL25         = 7;
%     protocol_id.s_plusR25         = 8;
%     protocol_id.s_plusL10         = 9;
%     protocol_id.s_plusR10         = 10;
%     protocol_id.s_minusL        = 11;    % low max speed
%     protocol_id.s_minusR        = 12;
    
    % number of blocks
    protocol.n_blocks = 1;
    
    % number of trials in each block
    protocol.n_trials = [1 1  1 1  1 1  1 1  1 1  1 1];

    protocolconfig.reward.duration = floor(config.reward.interleavingduration/(sum(protocol.n_trials(1:end))*protocol.n_blocks));
    
    trial_order = [];
    for i = 1:length(protocol.labels)
        trial_order = vertcat(trial_order,protocol.id(i)*ones(protocol.n_trials(i), protocol.n_blocks));
        total_trials(i) = protocol.n_trials(protocol.id(i));
    end

%     trial_order = [protocol_id.s_plusL80*ones(protocol.n_trials(protocol_id.s_plusL80), protocol.n_blocks); protocol_id.s_plusR80*ones(protocol.n_trials(protocol_id.s_plusR80), protocol.n_blocks); ...
%         protocol_id.s_plusL70*ones(protocol.n_trials(protocol_id.s_plusL70), protocol.n_blocks); protocol_id.s_plusR70*ones(protocol.n_trials(protocol_id.s_plusR70), protocol.n_blocks); ...
%         protocol_id.s_plusL60*ones(protocol.n_trials(protocol_id.s_plusL60), protocol.n_blocks); protocol_id.s_plusR60*ones(protocol.n_trials(protocol_id.s_plusR60), protocol.n_blocks); ...
%         protocol_id.s_plusL50*ones(protocol.n_trials(protocol_id.s_plusL50), protocol.n_blocks); protocol_id.s_plusR50*ones(protocol.n_trials(protocol_id.s_plusR60), protocol.n_blocks); ...
%         protocol_id.s_plusL40*ones(protocol.n_trials(protocol_id.s_plusL40), protocol.n_blocks); protocol_id.s_plusR40*ones(protocol.n_trials(protocol_id.s_plusR40), protocol.n_blocks); ...
%         protocol_id.s_plusL30*ones(protocol.n_trials(protocol_id.s_plusL30), protocol.n_blocks); protocol_id.s_plusR30*ones(protocol.n_trials(protocol_id.s_plusR30), protocol.n_blocks); ...
%         protocol_id.s_plusL20*ones(protocol.n_trials(protocol_id.s_plusL20), protocol.n_blocks); protocol_id.s_plusR20*ones(protocol.n_trials(protocol_id.s_plusR20), protocol.n_blocks); ...
%         protocol_id.s_minusL*ones(protocol.n_trials(protocol_id.s_minusL), protocol.n_blocks); protocol_id.s_minusR*ones(protocol.n_trials(protocol_id.s_minusR), protocol.n_blocks);];

    for i = 1 : protocol.n_blocks
%         I = randperm(sum([protocol.n_trials(protocol_id.s_plusL80),protocol.n_trials(protocol_id.s_plusR80),protocol.n_trials(protocol_id.s_plusL70),protocol.n_trials(protocol_id.s_plusR70),protocol.n_trials(protocol_id.s_plusL60),protocol.n_trials(protocol_id.s_plusR60),protocol.n_trials(protocol_id.s_plusL50),protocol.n_trials(protocol_id.s_plusR60),...
%             protocol.n_trials(protocol_id.s_plusL40),protocol.n_trials(protocol_id.s_plusR40),protocol.n_trials(protocol_id.s_plusL30),protocol.n_trials(protocol_id.s_plusR30),protocol.n_trials(protocol_id.s_plusL20),protocol.n_trials(protocol_id.s_plusR20),protocol.n_trials(protocol_id.s_minusL),protocol.n_trials(protocol_id.s_minusR)]));
        I = randperm(sum(total_trials));
        trial_order(:, i) = trial_order(I, i);
    end
    trial_order = trial_order(:);


    %% velocity array generator
    distance = 90;
    duration = 30;
    vmax_splus = [70 55 40 25 10];
    vmax_sminus = 10;
    peakwidth_splus = 2;
    peakwidth_sminus = 2;
    
    for i = 1 : length(trial_order)
    
        if trial_order(i) == protocol.id(1)     % s_plusL70
            
            trial.trial.stimulus_type = protocol.labels{1};
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

        elseif trial_order(i) == protocol.id(2)     % s_plusR70
            
            trial.trial.stimulus_type = protocol.labels{2};
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

         elseif trial_order(i) == protocol.id(3)    % s_plusL55
            
            trial.trial.stimulus_type = protocol.labels{3};
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

        elseif trial_order(i) == protocol.id(4)     % s_plusR55
            
            trial.trial.stimulus_type = protocol.labels{4};
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

        elseif trial_order(i) == protocol.id(5)     % s_plusL40
            
            trial.trial.stimulus_type = protocol.labels{5};
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

        elseif trial_order(i) == protocol.id(6)     % s_plusR40
            
            trial.trial.stimulus_type = protocol.labels{6};
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

        elseif trial_order(i) == protocol.id(7)     % s_plusL25
            
            trial.trial.stimulus_type = protocol.labels{7};
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

        elseif trial_order(i) == protocol.id(8)     % s_plusR25
            
            trial.trial.stimulus_type = protocol.labels{8};
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
        
        elseif trial_order(i) == protocol.id(9)     % s_plusL10
            
            trial.trial.stimulus_type = protocol.labels{9};
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

        elseif trial_order(i) == protocol.id(10)    % s_plusR10
            
            trial.trial.stimulus_type = protocol.labels{10};
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
        
        elseif trial_order(i) == protocol.id(end-1)     % s_minusL

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
            trial.stage.outer.enable = false;
            trial.stage.outer.distance = -distance;
            trial.stage.outer.max_vel = vmax_sminus; 
            trial.stage.outer.peakwidth = peakwidth_sminus;
            trial.stage.outer.mean_vel = abs(trial.stage.outer.distance)/trial.stage.motion_time;
            
            trial.vis.enable_vis_stim = enableVisStim;
            trial.vis.vis_stim_lable = 11;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        elseif trial_order(i) == protocol.id(end)       % s_minusR

            trial.trial.stimulus_type = protocol.labels{end};
            trial.trial.stimulus_typeid = length(protocol.labels);
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
            trial.vis.vis_stim_lable = 12;

            trial.waveform = voltagewaveform_generator_linear(trial.stage, config.nidaq.rate);
            
            % add protocol to the sequence
            seq.add(trial);

        end
    end
end