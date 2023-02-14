function config = config_yyao()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%
config.saving.enable                    = true;
config.saving.save_to                   = 'C:\Users\Margrie_Lab1\Documents\raw_data';  % where to save data
config.saving.config_file               = mfilename('fullpath');  % current file path
config.saving.main_dir                  = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab'; 
config.saving.git_dir                   = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\.git';  % git directory



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.rate                       = 10000;  % sampling rate of nidaq
config.nidaq.log_every                  = 1000;  % log data every number of samples  NIDAQ单位采样数据量



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
config.nidaq.ai.dev                     = 'Dev1';  % device name
config.nidaq.ai.channel_names           = {'stage_central', 'stage_outer', 'photodiode_left', 'photodiode_mid', 'photodiode_right', 'visual_stimulus_computer_minidaq', 'pump',  'lick'};  % nominal channel names (for reference)
config.nidaq.ai.channel_id              = 0:7;     % 使用的AI通道编号
config.nidaq.ai.offset                  = [0, 0, 0, 0, 0, 0, 0, 0];
config.nidaq.ai.scale                   = [1, 1, 1, 1, 1, 1, 1, 1];

config.offsets.enable                   = false;
config.offsets.error_mtx                = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = true;
config.nidaq.ao.dev                     = 'Dev1';
config.nidaq.ao.channel_names           = {'whitenoise'};
config.nidaq.ao.channel_id              = 0;
config.nidaq.ao.idle_offset             = 0;



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
config.nidaq.do.channel_names           = {'pump', 'visual_stimulus_start_trigger', 'ensemble'};
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

config.treadmill.enable                 = false;
config.treadmill.do_name                = ''; % name of digital output channel to use
config.treadmill.init_state             = []; % initial state of the solenoid (0=off, 1=on)

config.soloist_input_src.enable         = false;
config.soloist_input_src.do_name        = ''; % name of digital output channel to use
config.soloist_input_src.init_source    = ''; % initial source to listen to
config.soloist_input_src.teensy         = []; % which logic value is the teensy (0 or 1)

config.zero_teensy.enable               = false;
config.zero_teensy.do_name              = ''; % name of digital output channel to use

config.disable_teensy.enable            = false;
config.disable_teensy.do_name           = '';
config.disable_teensy.init_state        = [];

config.start_soloist.enable             = false;
config.start_soloist.do_name            = ''; % name of digital output channel to use

config.start_ensemble.enable            = true;
config.start_ensemble.do_name           = 'ensemble'; % name of digital output channel to use

config.visual_stimulus.enable           = true;
config.visual_stimulus.do_name          = 'visual_stimulus_start_trigger'; % name of digital output channel to use
config.visual_stimulus.init_state       = 0;

config.trigger_input.enable             = false;
config.trigger_input.init_source        = '';   % 'from_soloist' or 'from_teensy'

config.teensy_gain_up.enable            = false;
config.teensy_gain_up.do_name           = '';
config.teensy_gain_down.enable          = false;
config.teensy_gain_down.do_name         = '';



%%%%%%%%%%%%%%%%%%%%%%
% SOLOIST parameters %
%%%%%%%%%%%%%%%%%%%%%%
config.soloist.enable                   = false;
config.soloist.dir                      = '';
config.soloist.default_speed            = [];
config.soloist.v_per_cm_per_s           = [];
config.soloist.ai_offset                = [];
config.soloist.gear_scale               = [];
config.soloist.deadband                 = [];


%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%  default stage positions
%%%%%%%%%%%%%%%%%%%%%%
config.stage.start_pos                  = 0;
config.stage.back_limit                 = -100;
config.stage.forward_limit              = 100;
config.stage.max_limits                 = [-1000 1000];    % [stage远端范围, stage近端范围]


%%%%%%%%%%%%%%%%%%%%%%%
% ENSEMBLE parameters %
%%%%%%%%%%%%%%%%%%%%%%%

config.ensemble.enable                  = true;     % Whether to enable the Ensemble driver in RC2
config.ensemble.default_position        = [5 5];      % The default speed that the Ensemble will use when using direct analog control.
config.ensemble.default_speed           = [36 36];      % The default speed that the Ensemble will use when using direct analog control.
config.ensemble.max_limits              = [0.0001, 350];  % Max speed 

config.ensemble.ai_offset               = -500.0;   % The offset applied to the Ensemble analog input (mV).
config.ensemble.gear_scale              = -800;     % A scaling factor applied to the Ensemble analog input when being driven in gear mode.  double型数值，应用于'GearCamScaleFactor'的值，该值决定了电压和stage速度之间的增益。负值代表反向。
config.ensemble.all_axes                = [0, 1];   % The index of all controllable axes on the Ensemble. [central outer]
config.ensemble.target_axes             = [NaN NaN];        % The individual axis to be controlled by RC2.
config.ensemble.ai_channel              = [0,1];        % The analog input channel that Ensemble will listen for waveforms on.
config.ensemble.ao_channel              = [0,1];        % The analog output channel that Ensemble will replay servo feedback on.
config.ensemble.ao_servo_value          = 4;        % The servo loop value to replay on the ao_channel. 0 = None (off). 1 = Position Command (Counts). 2 = Position Feedback (Counts). 3 = Velocity Command (Counts / servo interrupt). 4 = Velocity Feedback (Counts / servo interrupt). 5 = Current Command (Amps). 6 = Current Feedback (Amps). 7 = Acceleration Command (Counts / msec2). 8 = Position Error (Counts). 9 = Piezo Voltage Command (Volts).  
config.ensemble.ao_scale_factor         = 0.1;      % A scaling factor that scales the servo loop value replayed on ao_channel for display in RC2.
config.ensemble.gearcam_source          = 2;        % The input source for gearing and camming motion on the Ensemble (0 = OpenLoop, 1 = ExternalPosition, 2 = Analog Input 0, 3 = Analog Input 1)
config.ensemble.deadband                = 0.005;    % The value (in volts) of the deadband to send to the controller.  死区。double型数值，以伏特为单位。应用于'GearCamAnalogDeadband'属性的值。低于该电压时，stage不会发生任何运动。
config.ensemble.default_gearsource = 1; % Default value for the gearcam_source.
config.ensemble.default_gearscalefactor = 1; % Default value for the gear_scale.
config.ensemble.analogdeadband = 0.05; % Default value for the deadband.
config.default_gainkpos = 128.7; % Default gain Kpos for the Ensemble.
config.ensemble.default_homeSetup = 0;              % HomeSetup Parameter. 0 = CCW/Negative Start Direction, 1 = CW/Positive Start Direction 


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
config.lick_detect.n_windows            = 1;    % 在ThemeParkRC2中protocol定义中被修改
config.lick_detect.window_size_ms       = 8000; % size of each window to determine licking 单次有效舔食时间窗口，单位为毫秒。在ThemeParkRC2中protocol定义中被修改
config.lick_detect.n_lick_windows       = 2;    % 在ThemeParkRC2中protocol定义中被修改
config.lick_detect.n_consecutive_windows= 4;    % 在ThemeParkRC2中protocol定义中被修改
config.lick_detect.trigger_channel      = 6;    % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID  即AI5，'visual_stimulus_computer_minidaq'对应通道
config.lick_detect.lick_channel         = 8;    % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID  即AI7，'lick'对应通道
config.lick_detect.detection_trigger_type = 1;  % 1 = rewards given in window after trigger rise detected, 2 = rewards given when trigger is high  % 在ThemeParkRC2中protocol定义中被修改
config.lick_detect.lick_threshold       = 1;


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
