function config = load_config()

config.use_calibration_file    = true;
config.calibration_file        = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\rc\main\calibration_20200123_2.mat';

config.saving.save_to           = 'C:\Users\Mateo\Desktop\DefaultData';
config.saving.config_file       = mfilename('fullpath');
config.saving.main_dir          = fileparts(fileparts(fileparts(config.saving.config_file))); % assume three levels deep
config.saving.git_dir           = fullfile(config.saving.main_dir, '.git');

config.stage.start_pos          = 1450;
config.stage.back_limit         = 1470;
config.stage.forward_limit      = 250;
config.stage.max_limits         = [1470, 15];

config.nidaq.rate               = 10000;
config.nidaq.log_every          = 1000;

config.nidaq.ai.dev                     = 'Dev2';
config.nidaq.ai.channel_names           = {'filtered_teensy', 'raw_teensy', 'stage', 'lick', 'pump', 'solenoid', 'photodiode', 'gain_change'};
config.nidaq.ai.channel_id              = 0:7;

% the following are only used if 'use_calibration_file' is set to false
if config.use_calibration_file
    load(config.calibration_file, 'calibration')
    if ~isequal(calibration.channel_names, config.nidaq.ai.channel_names)
        warning('calibration file channel names do not match the channel names provided')
    end
    config.nidaq.ai.offset                  = calibration.offset;
    config.nidaq.ai.scale                   = calibration.scale;
else
    config.nidaq.ai.offset                  = [0.503344396983876, 0.002920177684111, -0.013990593443526, 0, 0, 0, 0, 0]; % 
    config.nidaq.ai.scale                   = [40.034026111683019, 39.697309817412304, -40, 1, 1, 1, 1, 1];
end

config.nidaq.ao.dev             = 'Dev2';
config.nidaq.ao.channel_names   = {'velocity'};
config.nidaq.ao.channel_id      = 0;
config.nidaq.ao.idle_offset     = config.nidaq.ai.offset(1); % offset to apply to analog output

config.nidaq.co.dev             = 'Dev2';
config.nidaq.co.channel_names   = {'camera'};
config.nidaq.co.channel_id      = 0;
config.nidaq.co.init_delay      = 0;
config.nidaq.co.pulse_high      = 60;
config.nidaq.co.pulse_dur       = 167;  % ms, e.g. 125 = 80Hz 333;%
config.nidaq.co.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);

config.nidaq.do.dev             = 'Dev2';
config.nidaq.do.channel_names   = {'pump', 'multiplexer', 'solenoid', 'zero_teensy', 'visual_stimulus', 'soloist'};
config.nidaq.do.channel_id      = {'port0/line0', 'port0/line1', 'port0/line2', 'port0/line3', 'port0/line4', 'port0/line5'};
config.nidaq.do.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);

config.nidaq.di.dev             = 'Dev2';
config.nidaq.di.channel_names   = {'from_soloist', 'from_teensy'};
config.nidaq.di.channel_id      = {'port1/line0', 'port1/line1'};

config.teensy.exe               = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir               = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\teensy_ino';
config.teensy.start_script      = 'forward_only';

config.soloist.dir              = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\soloist_c\exe';
config.soloist.default_speed    = 200;
if config.use_calibration_file
    config.soloist.ai_offset    = calibration.filtTeensy2soloist_offset;
    config.soloist.gear_scale   = calibration.gear_scale;
    config.soloist.deadband     = calibration.deadband_V;
else
    config.soloist.ai_offset    = -508.0;
    config.soloist.gear_scale   = -4000;
    config.soloist.deadband     = 0.005;
end

config.pump.do_name             = 'pump';
config.pump.init_state          = 0;

config.reward.randomize         = false;
config.reward.min_time          = 3;
config.reward.max_time          = 7;
config.reward.duration          = 50;

config.treadmill.do_name        = 'solenoid';
config.treadmill.init_state     = 1;

config.soloist_input_src.do_name = 'multiplexer';
config.soloist_input_src.init_source = 'teensy';
config.soloist_input_src.teensy = 1;

config.zero_teensy.do_name      = 'zero_teensy';

config.start_soloist.do_name    = 'soloist';

config.visual_stimulus.do_name  = 'visual_stimulus';
config.visual_stimulus.init_state = 1;

config.trigger_input.init_source = 'from_soloist'; % 'from_soloist' or 'from_teensy'

config.plotting                 = plotting_config();
