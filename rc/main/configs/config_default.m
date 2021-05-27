function config = config_default(use_calibration)

% by default load a calibration file
VariableDefault('use_calibration', true);


% whether to use calibration file and its location
config.use_calibration_file             = use_calibration;
config.calibration_file                 = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\rc\main\calibration\calibration_20200707_b.mat';


%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%
config.saving.enable                    = true;
config.saving.save_to                   = 'C:\Users\Mateo\Desktop\DefaultData'; % where to save data
config.saving.config_file               = mfilename('fullpath');  % current file path
config.saving.main_dir                  = fileparts(fileparts(fileparts(config.saving.config_file))); % assume three levels deep
config.saving.git_dir                   = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\.git';  % git directory



%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%  default stage positions
%%%%%%%%%%%%%%%%%%%%%%
config.stage.start_pos                  = 1450;
config.stage.back_limit                 = 1470;
config.stage.forward_limit              = 250;
config.stage.max_limits                 = [1470, 15];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.rate                       = 10000;  % sampling rate of nidaq
config.nidaq.log_every                  = 1000;  % log data every number of samples



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
config.nidaq.ai.dev                     = 'Dev2';
config.nidaq.ai.channel_names           = {'filtered_teensy', 'filtered_teensy_2', 'stage', 'lick', 'pump', 'solenoid', 'photodiode', 'minidaq_ao0', 'multiplexer_output'};
config.nidaq.ai.channel_id              = [0:7, 16];
config.nidaq.ai.offset                  = [0.5, 0, 0, 0, 0, 0, 0, 0]; % 
config.nidaq.ai.scale                   = [40, 40, -40, 1, 1, 1, 1, 1];

config.offsets.enable                   = true;
config.offsets.error_mtx                = zeros(4, 7);

% offsets and scales to apply to the 
if config.use_calibration_file % get the offsets from the calibration file
    
    load(config.calibration_file, 'calibration') % load the calibration file
    config.offsets.error_mtx                 = calibration.offset_error_mtx;
    
    % make sure that the calibration file matches the list of channel names provided
    if ~isequal(calibration.channel_names, config.nidaq.ai.channel_names)
        warning('calibration file channel names do not match the channel names provided')
    end
    
    config.nidaq.ai.offset                  = calibration.offset;
    config.nidaq.ai.scale                   = calibration.scale;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = true;
config.nidaq.ao.dev                     = 'Dev2';
config.nidaq.ao.channel_names           = {'velocity'};
config.nidaq.ao.channel_id              = 0;
config.nidaq.ao.idle_offset             = 0.5;

if config.use_calibration_file
    config.nidaq.ao.idle_offset     = calibration.nominal_stationary_offset - ...
                                      calibration.offset_error_mtx(3, 5) + ...
                                      calibration.offset_error_mtx(3, 4);
end



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
config.nidaq.do.channel_names           = {'pump', 'multiplexer', 'solenoid', 'zero_teensy', 'visual_stimulus', 'soloist', 'disable_teensy'};
config.nidaq.do.channel_id              = {'port0/line0', 'port0/line1', 'port0/line2', 'port0/line3', 'port0/line4', 'port0/line5', 'port0/line6'};
config.nidaq.do.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = true;
config.nidaq.di.dev                     = 'Dev2';
config.nidaq.di.channel_names           = {'from_soloist', 'from_teensy'};
config.nidaq.di.channel_id              = {'port1/line0', 'port1/line1'};



%%%%%%%%%%%%%%%%%%%%%%
% Device parameters %
%%%%%%%%%%%%%%%%%%%%%%
config.pump.enable                      = true;
config.pump.do_name                     = 'pump';  % name of digital output channel to use
config.pump.init_state                  = 0;  % initial state of the pump (0=off, 1=on)

config.treadmill.enable                 = true;
config.treadmill.do_name                = 'solenoid';
config.treadmill.init_state             = 1;

config.soloist_input_src.enable         = true;
config.soloist_input_src.do_name        = 'multiplexer';
config.soloist_input_src.init_source    = 'teensy';
config.soloist_input_src.teensy         = 1;

config.zero_teensy.enable               = true;
config.zero_teensy.do_name              = 'zero_teensy';

config.disable_teensy.enable            = true; 
config.disable_teensy.do_name           = 'disable_teensy';
config.disable_teensy.init_state        = 0;

config.start_soloist.enable             = true;
config.start_soloist.do_name            = 'soloist';

config.visual_stimulus.enable           = true;
config.visual_stimulus.do_name          = 'visual_stimulus';
config.visual_stimulus.init_state       = 1;

config.trigger_input.enable             = true;
config.trigger_input.init_source        = 'from_soloist'; % 'from_soloist' or 'from_teensy'

config.teensy_gain_up.enable            = true;
config.teensy_gain_up.do_name           = 'teensy_gain_up';
config.teensy_gain_down.enable          = false;
config.teensy_gain_down.do_name         = 'teensy_gain_down';



%%%%%%%%%%%%%%%%%%%%%%
% TEENSY parameters %%
%%%%%%%%%%%%%%%%%%%%%%
config.teensy.enable                    = true;
config.teensy.exe                       = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir                       = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\teensy_ino';
config.teensy.start_script              = 'forward_only';



%%%%%%%%%%%%%%%%%%%%%%
% SOLOIST parameters %
%%%%%%%%%%%%%%%%%%%%%%
config.soloist.enable                   = true;
config.soloist.dir                      = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\soloist_c\exe';
config.soloist.default_speed            = 200;
config.soloist.v_per_cm_per_s           = 25/100;
config.soloist.ai_offset                = -500.0;
config.soloist.gear_scale               = -4000;
config.soloist.deadband                 = 0.005;

if config.use_calibration_file
    config.soloist.ai_offset            = 1e3 * (- calibration.nominal_stationary_offset + calibration.offset_error_mtx(3, 2));
    config.soloist.gear_scale           = calibration.gear_scale;
    config.soloist.deadband             = 1.2*calibration.deadband_V;
end



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
config.lick_detect.enable               = false;
config.lick_detect.n_windows            = [];
config.lick_detect.window_size_ms       = [];   % size of each window to determine licking
config.lick_detect.n_lick_windows       = [];
config.lick_detect.trigger_channel      = [];   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID
config.lick_detect.lick_channel         = [];   % index of channel in "config.nidaq.ai.channel_names" not analog input channel ID



%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOUND %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.sound.enable                     = true;
config.sound.filename                   = 'white_noise.wav';



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%
config.plotting                         = plotting_config();  % get plotting configuration from a separate file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
