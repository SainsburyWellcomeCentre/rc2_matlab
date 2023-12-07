function config = config_passive_protocol(use_calibration)

% by default load a calibration file
VariableDefault('use_calibration', true);


% whether to use calibration file and its location
config.use_calibration_file             = use_calibration;
config.calibration_file                 = 'C:\Users\Mateo\Documents\repos\rc2_matlab\rc\user\mateo\calibration\calibration_20200707_b.mat';


%%%%%%%%%%%%
% SAVING %%%
%%%%%%%%%%%%

% where to save data
config.saving.save_to                   = 'C:\Users\Mateo\Desktop\DefaultData';

% automatically gets these file locations and directories
config.saving.config_file               = mfilename('fullpath');        % current file path
config.saving.main_dir                  = fileparts(fileparts(fileparts(config.saving.config_file))); % assume three levels deep
config.saving.git_dir                   = 'C:\Users\Mateo\Documents\repos\rc2_matlab\.git';  % git directory


%%%%%%%%%%%%%%%%%%%%%%
% STAGE parameters %%%
%%%%%%%%%%%%%%%%%%%%%%

% default stage positions
config.stage.start_pos                  = 1450;
config.stage.back_limit                 = 1470;
config.stage.forward_limit              = 250;
config.stage.max_limits                 = [1470, 15];

if config.use_calibration_file
    % load the calibration file
    load(config.calibration_file, 'calibration')
    
    config.offset_error_mtx                 = calibration.offset_error_mtx;
else
    config.offset_error_mtx                 = zeros(4, 7);
end

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

% device name
config.nidaq.ai.dev                     = 'Dev2';
% nominal channel names (for reference)
config.nidaq.ai.channel_names           = {'filtered_teensy', 'filtered_teensy_2', 'stage', 'lick', 'pump', 'solenoid', 'photodiode', 'minidaq_ao0', 'multiplexer_output'};
% 
config.nidaq.ai.channel_id              = [0:7, 16];


% offsets and scales to apply to the 
if config.use_calibration_file
    
    % make sure that the calibration file matches the list of channel names
    % provided
    if ~isequal(calibration.channel_names, config.nidaq.ai.channel_names)
        warning('calibration file channel names do not match the channel names provided')
    end
    
    % get the offsets from the calibration file
    config.nidaq.ai.offset                  = calibration.offset;
    config.nidaq.ai.scale                   = calibration.scale;
else
    % default to use if no calibration file
    config.nidaq.ai.offset                  = [0.5, 0, 0, 0, 0, 0, 0, 0]; % 
    config.nidaq.ai.scale                   = [40, 1, -40, 1, 1, 1, 1, 1];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config.nidaq.ao.dev             = 'Dev2';
config.nidaq.ao.channel_names   = {'velocity', 'delayed_velocity'};
config.nidaq.ao.channel_id      = [0, 1];
if config.use_calibration_file
    config.nidaq.ao.idle_offset     = calibration.nominal_stationary_offset - ...
        calibration.offset_error_mtx(3, 5) + calibration.offset_error_mtx(3, 4);
else
    config.nidaq.ao.idle_offset     = 0.5;
end
config.nidaq.ao.idle_offset = config.nidaq.ao.idle_offset([1, 1]);

config.include_delayed_copy = true;
config.delay_ms = 80;

% offset to apply to analog output

% 
% if config.use_calibration_file
%     config.nidaq.ao.offset_error_solenoid_on = calibration.ni_ao_error_solenoid_on;
%     config.nidaq.ao.offset_error_solenoid_off = calibration.ni_ao_error_solenoid_off;
% else
%     config.nidaq.ao.offset_error_solenoid_on = 0;
%     config.nidaq.ao.offset_error_solenoid_off = 0;
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUNTER OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config.nidaq.co.dev             = 'Dev2';
config.nidaq.co.channel_names   = {'camera'};
config.nidaq.co.channel_id      = 0;
config.nidaq.co.init_delay      = 0;
config.nidaq.co.pulse_high      = 60;
config.nidaq.co.pulse_dur       = 167;  % ms, e.g. 125 = 80Hz 333;%
config.nidaq.co.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config.nidaq.do.dev             = 'Dev2';
config.nidaq.do.channel_names   = {'pump', 'multiplexer', 'solenoid', 'zero_teensy', 'visual_stimulus', 'soloist', 'disable_teensy', 'vis_stim_gain'};
config.nidaq.do.channel_id      = {'port0/line0', 'port0/line1', 'port0/line2', 'port0/line3', 'port0/line4', 'port0/line5', 'port0/line6', 'port0/line23'};
config.nidaq.do.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config.nidaq.di.dev             = 'Dev2';
config.nidaq.di.channel_names   = {'from_soloist', 'from_teensy'};
config.nidaq.di.channel_id      = {'port1/line0', 'port1/line1'};


%%%%%%%%%%%%%%%%%%%%%%
% TEENSY parameters %%
%%%%%%%%%%%%%%%%%%%%%%

config.teensy.exe               = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir               = 'C:\Users\Mateo\Documents\repos\rc2_matlab\teensy_ino';
config.teensy.start_script      = 'forward_only';


%%%%%%%%%%%%%%%%%%%%%%
% SOLOIST parameters %
%%%%%%%%%%%%%%%%%%%%%%

config.soloist.dir              = 'C:\Users\Mateo\Documents\repos\rc2_matlab\soloist_c\exe';
config.soloist.default_speed    = 200;
config.soloist.v_per_cm_per_s   = 25/100;
if config.use_calibration_file
    config.soloist.ai_offset    = ...
        1e3 * (- calibration.nominal_stationary_offset + ...
                 calibration.offset_error_mtx(3, 2));
    config.soloist.gear_scale   = calibration.gear_scale;
    config.soloist.deadband     = 1.2*calibration.deadband_V;
else
    config.soloist.ai_offset            = -500.0;
    config.soloist.gear_scale           = -4000;
    config.soloist.deadband             = 0.005;
end


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

% name of digital output channel to use
config.pump.do_name                     = 'pump';
% initial state of the pump (0=off, 1=on)
config.pump.init_state                  = 0;

% name of digital output channel to use
config.treadmill.do_name                = 'solenoid';
% initial state of the solenoid (0=off, 1=on)
config.treadmill.init_state             = 1;

% name of digital output channel to use
config.soloist_input_src.do_name        = 'multiplexer';
% initial source to listen to
config.soloist_input_src.init_source    = 'teensy';
% which logic value is the teensy (0 or 1)
config.soloist_input_src.teensy         = 1;

% name of digital output channel to use
config.zero_teensy.do_name              = 'zero_teensy';

% 
config.disable_teensy.do_name           = 'disable_teensy';
config.disable_teensy.init_state        = 0;

% name of digital output channel to use
config.start_soloist.do_name            = 'soloist';

% name of digital output channel to use
config.visual_stimulus.do_name          = 'visual_stimulus';
config.visual_stimulus.init_state       = 1;

% name of digital output channel to use
config.vis_stim_gain.do_name            = 'vis_stim_gain';
config.vis_stim_gain.init_state         = 0;

% name of digital input channel to use
config.trigger_input.init_source        = 'from_soloist'; % 'from_soloist' or 'from_teensy'

% for triggers to the teensy gain
config.teensy_gain_up.do_name           = 'teensy_gain_up';
config.teensy_gain_down.do_name         = 'teensy_gain_down';

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get plotting configuration from a separate file
config.plotting                         = plotting_config();



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
