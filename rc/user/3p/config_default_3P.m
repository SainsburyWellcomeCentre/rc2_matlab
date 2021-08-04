function config = config_default_3P()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%

% where to save data
config.saving.enable                    = true;
config.saving.save_to                   = 'D:\Data\Default3PData';

% automatically gets these file locations and directories
config.saving.config_file               = mfilename('fullpath');        % current file path
config.saving.main_dir                  = 'C:\Users\treadmill\Code\rc2_matlab'; % assume three levels deep
config.saving.git_dir                   = 'C:\Users\treadmill\Code\rc2_matlab\.git';  % git directory


%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%
%%%%%%%%%%%%%%%%%%%%%%

% default stage positions
config.stage.start_pos                  = 1450;
config.stage.back_limit                 = 1470;
config.stage.forward_limit              = 250;
config.stage.max_limits                 = [1470, 15];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sampling rate of nidaq
config.nidaq.rate                       = 10000;

% log data every number of samples
config.nidaq.log_every                  = 1000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
% device name
config.nidaq.ai.dev                     = 'Dev1';
% nominal channel names (for reference)
config.nidaq.ai.channel_names           = {'camera', 'scanimage_frameclock', 'photodiode1', 'photodiode2','grab_start'};
% 
config.nidaq.ai.channel_id              = [0:4];
config.nidaq.ai.offset                  = [0, 0, 0, 0, 0]; % 
config.nidaq.ai.scale                   = [1, 1, 1, 1, 1];

config.offsets.enable                   = false;
config.offsets.error_mtx                = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = false;
config.nidaq.ao.dev                     = 'Dev1';
config.nidaq.ao.channel_names           = {'velocity'};
config.nidaq.ao.channel_id              = 0;
config.nidaq.ao.idle_offset             = 0.5;



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
config.nidaq.do.channel_names           = {'pump', 'multiplexer', 'solenoid', 'zero_teensy', 'visual_stimulus', 'soloist', 'disable_teensy'};
config.nidaq.do.channel_id              = {'port0/line0', 'port0/line1', 'port0/line2', 'port0/line3', 'port0/line4', 'port0/line5', 'port0/line6'};
config.nidaq.do.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = false;
config.nidaq.di.dev                     = 'Dev1';
config.nidaq.di.channel_names           = {'from_soloist', 'from_teensy'};
config.nidaq.di.channel_id              = {'port0/line0', 'port0/line1'};


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
% Reward parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.reward.randomize                 = false;
config.reward.min_time                  = 3;
config.reward.max_time                  = 7;
config.reward.duration                  = 50;



%%%%%%%%%%%%%%%%%%%%%%
% Device parameters %
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




%%%%%%%%%%%%%%%%%%%%%%%%%%
% LICK DETECTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.lick_detect.enable               = false;
config.lick_detect.n_windows            = 1;
config.lick_detect.window_size_ms       = 8000; % size of each window to determine licking
config.lick_detect.n_lick_windows       = 2;
config.lick_detect.n_consecutive_windows= 4;
config.lick_detect.trigger_channel      = 3;   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.lick_channel         = 5;   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.detection_trigger_type = 1;  % 1 = rewards given in window after trigger rise detected, 2 = rewards given when trigger is high
config.lick_detect.lick_threshold       = 2;



%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = false;
config.sound.filename                   = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get plotting configuration from a separate file
config.plotting                         = plotting_config_3p();



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
