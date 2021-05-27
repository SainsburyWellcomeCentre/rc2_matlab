function config = config_sweiler()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%
config.saving.enable                    = true;
config.saving.save_to                   = '';  % where to save data
config.saving.config_file               = mfilename('fullpath');  % current file path
config.saving.main_dir                  = '';  
config.saving.git_dir                   = '';  % git directory



%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%  default stage positions
%%%%%%%%%%%%%%%%%%%%%%
config.stage.start_pos                  = [];
config.stage.back_limit                 = [];
config.stage.forward_limit              = [];
config.stage.max_limits                 = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.rate                       = 10000;  % sampling rate of nidaq
config.nidaq.log_every                  = 1000;  % log data every number of samples



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
config.nidaq.ai.dev                     = 'Dev2';  % device name
config.nidaq.ai.channel_names           = {'filtered_teensy', 'lick', 'pump', 'visual_stimulus_computer_minidaq', 'photodiode_1', 'photodiode_2'};  % nominal channel names (for reference)
config.nidaq.ai.channel_id              = 0:5;
config.nidaq.ai.offset                  = [0.5, 0, 0, 0, 0, 0];
config.nidaq.ai.scale                   = [40, 1, 1, 1, 1, 1];

config.offsets.enable                   = false;
config.offsets.error_mtx                = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = false;
config.nidaq.ao.dev                     = '';
config.nidaq.ao.channel_names           = {};
config.nidaq.ao.channel_id              = [];
config.nidaq.ao.idle_offset             = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUNTER OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.co.enable                  = true;
config.nidaq.co.dev                     = 'Dev2';
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
config.nidaq.do.dev                     = 'Dev2';
config.nidaq.do.channel_names           = {'pump', 'visual_stimulus_start_trigger'};
config.nidaq.do.channel_id              = {'port0/line0', 'port0/line1'};
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
% TEENSY parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.teensy.enable                    = false;
config.teensy.exe                       = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir                       = '';
config.teensy.start_script              = 'forward_only';



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
% REWARD parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.reward.randomize                 = false;
config.reward.min_time                  = 3;
config.reward.max_time                  = 7;
config.reward.duration                  = 50;



%%%%%%%%%%%%%%%%%%%%%%%%%%
% LICK DETECTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
% if enabled reward will be given if a lick is detected
config.lick_detect.enabled              = true;
config.lick_detect.n_windows            = 1;
config.lick_detect.window_size_ms       = 8000; % size of each window to determine licking
config.lick_detect.n_lick_windows       = 1;
config.lick_detect.trigger_channel      = 4;   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.lick_channel         = 2;   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.detection_window_is_triggered = false;



%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = false;
config.sound.filename                   = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.plotting                         = plotting_config_sweiler();  % get plotting configuration from a separate file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
