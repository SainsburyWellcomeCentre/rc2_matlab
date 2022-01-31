function config = config_default_template()

%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%

% where to save data
config.saving.enable                    = false;
config.saving.save_to                   = '';

% automatically gets these file locations and directories
config.saving.config_file               = mfilename('fullpath');
config.saving.main_dir                  = '';  % 
config.saving.git_dir                   = '';  % git directory
config.saving.single_trial_log_channel_name = '';


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
config.nidaq.ai.enable                  = false;
config.nidaq.ai.dev                     = '';  % e.g. 'Dev1'
config.nidaq.ai.channel_names           = {''};
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
config.nidaq.ao.channel_names           = {''};
config.nidaq.ao.channel_id              = [];
config.nidaq.ao.idle_offset             = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUNTER OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.co.enable                  = false;     
config.nidaq.co.dev                     = '';   
config.nidaq.co.channel_names           = {''};   
config.nidaq.co.channel_id              = [];    
config.nidaq.co.init_delay              = [];    
config.nidaq.co.pulse_high              = [];   
config.nidaq.co.pulse_dur               = [];  % # samples, e.g. 125 = 80Hz
config.nidaq.co.clock_src               = '';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.do.enable                  = false;
config.nidaq.do.dev                     = '';
config.nidaq.do.channel_names           = {''};
config.nidaq.do.channel_id              = {''};
config.nidaq.do.clock_src               = '';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = false;
config.nidaq.di.dev                     = '';
config.nidaq.di.channel_names           = {''};
config.nidaq.di.channel_id              = {''};


%%%%%%%%%%%%%%%%%%%%%%
% TEENSY parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.teensy.enable                    = false;
config.teensy.exe                       = '';
config.teensy.dir                       = 'C:\Users\treadmill\Code\rc2_matlab\teensy_ino';
config.teensy.start_script              = 'forward_only';



%%%%%%%%%%%%%%%%%%%%%%
% SOLOIST parameters %
%%%%%%%%%%%%%%%%%%%%%%
config.soloist.enable                   = true;
config.soloist.dir                      = 'C:\Users\treadmill\Code\rc2_matlab\soloist_c\exe';
config.soloist.default_speed            = 200;
config.soloist.v_per_cm_per_s           = 2.5/100;
config.soloist.ai_offset                = -500;
config.soloist.gear_scale               = -400000;
config.soloist.deadband                 = 0.005;



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

config.treadmill.enable                 = true;
config.treadmill.do_name                = 'solenoid'; % name of digital output channel to use
config.treadmill.init_state             = 1; % initial state of the solenoid (0=off, 1=on)

config.soloist_input_src.enable         = true;
config.soloist_input_src.do_name        = 'multiplexer'; % name of digital output channel to use
config.soloist_input_src.init_source    = 'teensy'; % initial source to listen to
config.soloist_input_src.teensy         = 1; % which logic value is the teensy (0 or 1)

config.zero_teensy.enable               = true;
config.zero_teensy.do_name              = 'zero_teensy'; % name of digital output channel to use

config.disable_teensy.enable            = true;
config.disable_teensy.do_name           = 'disable_teensy';
config.disable_teensy.init_state        = 0;

config.start_soloist.enable             = true;
config.start_soloist.do_name            = 'soloist'; % name of digital output channel to use

config.visual_stimulus.enable           = true;
config.visual_stimulus.do_name          = 'visual_stimulus'; % name of digital output channel to use
config.visual_stimulus.init_state       = 0;

config.trigger_input.enable             = true;
config.trigger_input.init_source        = 'from_soloist';   % 'from_soloist' or 'from_teensy'

config.teensy_gain_up.enable            = false;
config.teensy_gain_up.do_name           = '';
config.teensy_gain_down.enable          = false;
config.teensy_gain_down.do_name         = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% LICK DETECTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.lick_detect.enable               = false;



%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = false;
config.sound.filename                   = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get plotting configuration from a separate file
config.plotting                         = plotting_config_3p_soloist_setup();



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
