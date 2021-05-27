function config = config_empty()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%
config.saving.enable                    = false;
config.saving.save_to                   = tempdir;  % where to save data
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
config.nidaq.rate                       = [];  % sampling rate of nidaq
config.nidaq.log_every                  = [];  % log data every number of samples



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = false;
config.nidaq.ai.dev                     = '';  % device name
config.nidaq.ai.channel_names           = {};  % nominal channel names (for reference)
config.nidaq.ai.channel_id              = [];
config.nidaq.ai.offset                  = [];
config.nidaq.ai.scale                   = [];

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
config.nidaq.co.enable                  = false;
config.nidaq.co.dev                     = '';
config.nidaq.co.channel_names           = {};
config.nidaq.co.channel_id              = [];
config.nidaq.co.init_delay              = [];
config.nidaq.co.pulse_high              = [];
config.nidaq.co.pulse_dur               = [];  % ms, e.g. 125 = 80Hz 333;%
config.nidaq.co.clock_src               = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.do.enable                  = false;
config.nidaq.do.dev                     = '';
config.nidaq.do.channel_names           = {};
config.nidaq.do.channel_id              = {};
config.nidaq.do.clock_src               = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = false;
config.nidaq.di.dev                     = '';
config.nidaq.di.channel_names           = {''};
config.nidaq.di.channel_id              = {''};



%%%%%%%%%%%%%%%%%%%%%%
% Device parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.pump.enable                      = false;
config.pump.do_name                     = ''; % name of digital output channel to use
config.pump.init_state                  = []; % initial state of the pump (0=off, 1=on)

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

config.visual_stimulus.enable           = false;
config.visual_stimulus.do_name          = ''; % name of digital output channel to use
config.visual_stimulus.init_state       = [];

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
config.teensy.exe                       = '';
config.teensy.dir                       = '';
config.teensy.start_script              = '';



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
config.reward.min_time                  = [];
config.reward.max_time                  = [];
config.reward.duration                  = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%
% LICK DETECTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
% if enabled reward will be given if a lick is detected
config.lick_detect.enable               = false;
config.lick_detect.n_windows            = [];
config.lick_detect.window_size_ms       = [];   % size of each window to determine licking
config.lick_detect.n_lick_windows       = [];
config.lick_detect.trigger_channel      = [];   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.lick_channel         = [];   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID



%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = false;
config.sound.filename                   = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.plotting                         = plotting_config_empty();  % get plotting configuration from a separate file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
