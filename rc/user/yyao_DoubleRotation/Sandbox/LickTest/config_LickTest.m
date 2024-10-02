function config = config_LickTest()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%
config.saving.enable                    = true;
config.saving.save_to                   = 'C:\Users\Margrie_Lab1\Documents\raw_data';  % where to save data
config.saving.config_file               = mfilename('fullpath');  % current file path
config.saving.main_dir                  = 'C:\Users\Margrie_Lab1\Documents\repos\swc\rc2_matlab'; 
config.saving.git_dir                   = 'C:\Users\Margrie_Lab1\Documents\repos\swc\rc2_matlab\.git';  % git directory



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.rate                       = 10000;  % sampling rate of nidaq
config.nidaq.log_every                  = 1000;  % log data every number of samples



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
config.nidaq.ai.dev                     = 'Dev1';  % device name
% config.nidaq.ai.channel_names           = {'stage_central', 'stage_outer', 'photodiode_left', 'photodiode_mid', 'photodiode_right', 'LickDetect_trigger', 'pump',  'lick',  'VisualStim_trigger'};  % nominal channel names (for reference)
config.nidaq.ai.channel_names           = {'stage_central', 'stage_outer', 'photodiode_left', 'LickDetect_trigger', 'pump',  'lick',  'VisualStim_trigger'};  % nominal channel names (for reference)
% config.nidaq.ai.channel_id              = [0:7 20]; 
config.nidaq.ai.channel_id              = [0:2 5:7 20];
% config.nidaq.ai.offset                  = [0.004, 0.005, -0.014, -0.008, -0.102, 0.0077, -0.0004, 0, 0];
config.nidaq.ai.offset                  = [0.004, 0.005, -0.014, 0.0077, -0.0004, 0, 0];
config.nidaq.ai.scale                   = [1, 1, 1, 1, 1, 1, 1];

config.offsets.enable                   = false;
config.offsets.error_mtx                = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = true;
config.nidaq.ao.dev                     = 'Dev1';
config.nidaq.ao.channel_names           = {'waveform_0',  'waveform_1'};
config.nidaq.ao.channel_id              = [0, 1];
config.nidaq.ao.idle_offset             = [0, 0];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUNTER OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.co.enable                  = true;
config.nidaq.co.dev                     = 'Dev1';
config.nidaq.co.channel_names           = {'camera'};
config.nidaq.co.channel_id              = 0;
config.nidaq.co.init_delay              = 0;
config.nidaq.co.pulse_high              = 60;
config.nidaq.co.pulse_dur               = 167;  % ms, e.g. 125 = 80Hz 333;%
config.nidaq.co.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.do.enable                  = true;
config.nidaq.do.dev                     = 'Dev1';
config.nidaq.do.channel_names           = {'pump', 'visual_stimulus_start_trigger', 'waveform_peak_trigger'};
config.nidaq.do.channel_id              = {'port0/line0', 'port0/line1', 'port0/line2'};
config.nidaq.do.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = false;
config.nidaq.di.dev                     = '';
config.nidaq.di.channel_names           = {};
config.nidaq.di.channel_id              = {};



%%%%%%%%%%%%%%%%%%%%%%
% Device parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.pump.enable                      = true;
config.pump.do_name                     = 'pump'; % name of digital output channel to use
config.pump.init_state                  = 0; % initial state of the pump (0=off, 1=on)

config.visual_stimulus.enable           = true;
config.visual_stimulus.do_name          = 'visual_stimulus_start_trigger'; % name of digital output channel to use
config.visual_stimulus.init_state       = 0;

config.trailstart_trigger.enable        = true;
config.trailstart_trigger.do_name       = 'trail_start_trigger'; % name of digital output channel to use
config.trailstart_trigger.init_state    = 0;

config.waveformpeak_trigger.enable        = true;
config.waveformpeak_trigger.do_name       = 'waveform_peak_trigger'; % name of digital output channel to use
config.waveformpeak_trigger.init_state    = 0;


%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%  default stage positions
%%%%%%%%%%%%%%%%%%%%%%
config.stage.start_pos                  = 0;
config.stage.back_limit                 = -100;
config.stage.forward_limit              = 100;
config.stage.max_limits                 = [-180 180];    % [stage min position , stage max position]


%%%%%%%%%%%%%%%%%%%%%%%
% ENSEMBLE parameters %
%%%%%%%%%%%%%%%%%%%%%%%

config.ensemble.enable                  = true;             % Whether to enable the Ensemble driver in RC2
config.ensemble.default_position        = [5 5];            % The default speed that the Ensemble will use when using direct analog control.
config.ensemble.default_speed           = [36 36];          % The default speed that the Ensemble will use when using direct analog control.
config.ensemble.speed_limits            = [0.0001, 100];    % Speed limits [min max] 

config.ensemble.ai_offset               = [-0.00095 0.5];   % The offset applied to the Ensemble analog input (mV). Run 'calibrate_zero' function in 'Ensemble' class to get the value (ai_offset = -offset_error).
config.ensemble.gear_scale              = [2870 2150]/3;      % A scaling factor applied to the Ensemble analog input when being driven in gear mode.  
config.ensemble.all_axes                = [0, 1];           % The index of all controllable axes on the Ensemble. [central outer]
config.ensemble.target_axes             = [NaN NaN];        % The individual axis to be controlled by RC2.
config.ensemble.ai_channel              = [0,0];            % The analog input channel that Ensemble will listen for waveforms on.
config.ensemble.ao_channel              = [0,0];            % The analog output channel that Ensemble will replay servo feedback on.
config.ensemble.ao_servo_value          = 4;                % The servo loop value to replay on the ao_channel. 0 = None (off). 1 = Position Command (Counts). 2 = Position Feedback (Counts). 3 = Velocity Command (Counts / servo interrupt). 4 = Velocity Feedback (Counts / servo interrupt). 5 = Current Command (Amps). 6 = Current Feedback (Amps). 7 = Acceleration Command (Counts / msec2). 8 = Position Error (Counts). 9 = Piezo Voltage Command (Volts).  
config.ensemble.ao_scale_factor         = [0.00275 , 0.00370]*3;              % A scaling factor that scales the servo loop value replayed on ao_channel for display in RC2. 
config.ensemble.gearcam_source          = 2;                % The input source for gearing and camming motion on the Ensemble (0 = OpenLoop, 1 = ExternalPosition, 2 = Analog Input 0, 3 = Analog Input 1)
config.ensemble.deadband                = 0.005;            % The value (in volts) of the deadband to send to the controller.  
config.ensemble.default_gearsource      = 1;                % Default value for the gearcam_source.
config.ensemble.default_gearscalefactor = 1;                % Default value for the gear_scale.
config.ensemble.analogdeadband          = 0.05;             % Default value for the deadband.
config.default_gainkpos                 = [86.1 97.48];     % Default gain Kpos for the Ensemble.
config.ensemble.default_homeSetup       = 0;                % HomeSetup Parameter. 0 = CCW/Negative Start Direction, 1 = CW/Positive Start Direction 


%%%%%%%%%%%%%%%%%%%%%%
% REWARD parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.reward.randomize                 = false;
config.reward.min_time                  = 3;
config.reward.max_time                  = 7;
config.reward.duration                  = 150;


%%%%%%%%%%%%%%%%%%%%%%%%%%
% LICK DETECTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
% if enabled reward will be given if a lick is detected
config.lick_detect.enable               = true;
config.lick_detect.n_windows            = 1;    
config.lick_detect.window_size_ms       = 8000; 
config.lick_detect.n_lick_windows       = 2;    
config.lick_detect.n_consecutive_windows= 4;    
config.lick_detect.trigger_channel      = 4;    % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID  ie AI5，'LickDetect_trigger' channel
config.lick_detect.lick_channel         = 6;    % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID  ie AI7，'lick' channel
config.lick_detect.detection_trigger_type = 1;  % 1 = rewards given in window after trigger rise detected, 2 = rewards given when trigger is high  
config.lick_detect.lick_threshold       = 1;
config.lick_detect.delay = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = true;
config.sound.filename                   = 'C:\Users\Margrie_Lab1\Documents\MATLAB\audio\white_noise.wav';

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.plotting                         = plotting_config_yyao();  % get plotting configuration from a separate file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
