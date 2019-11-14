function config = load_config()


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


config.nidaq.ai.dev             = 'Dev2';
config.nidaq.ai.channel_names   = {'filtered_teensy', 'raw_teensy', 'stage', 'lick', 'pump', 'solenoid', 'photodiode'};
config.nidaq.ai.offset          = [0.503344396983876, 0.002920177684111, -0.013990593443526, 0, 0, 0, 0]; % 
config.nidaq.ai.scale           = [40.034026111683019, 39.697309817412304, -40, 1, 1, 1, 1];
config.nidaq.ai.channel_id      = 0:6;


config.nidaq.ao.dev             = 'Dev2';
config.nidaq.ao.channel_names   = {'velocity'};
config.nidaq.ao.channel_id      = 0;
config.nidaq.ao.idle_offset     = 0.5; % offset to apply to analog output

config.nidaq.co.dev             = 'Dev2';
config.nidaq.co.channel_names   = {'camera'};
config.nidaq.co.channel_id      = 0;
config.nidaq.co.init_delay      = 0;
config.nidaq.co.pulse_high      = 60;
config.nidaq.co.pulse_dur       = 125;  % 80Hz
config.nidaq.co.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);


config.nidaq.do.dev             = 'Dev2';
config.nidaq.do.channel_names   = {'pump', 'multiplexer', 'solenoid', 'zero_teensy'};
config.nidaq.do.channel_id      = {'port0/line0', 'port0/line1', 'port0/line2', 'port0/line3'};
config.nidaq.do.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);

config.nidaq.di.dev             = 'Dev2';
config.nidaq.di.channel_names   = {'from_soloist', 'from_teensy'};
config.nidaq.di.channel_id      = {'port1/line0', 'port1/line1'};


config.teensy.exe               = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir               = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\teensy_ino';
config.teensy.start_script      = 'forward_only';


config.soloist.dir              = 'C:\Users\Mateo\Documents\rc_version2_0\rc2_matlab\soloist_c\exe';
config.soloist.default_speed    = 200;
config.soloist.teensy_offset    = -508.0;
config.soloist.ni_offset        = -508.0;
config.soloist.v_per_cm_per_s   = 1/40;

config.pump.do_name             = 'pump';
config.pump.init_state          = 0;

config.reward.randomize         = true;
config.reward.min_time          = 3;
config.reward.max_time          = 7;
config.reward.duration          = 50;


config.treadmill.do_name        = 'solenoid';
config.treadmill.init_state     = 1;


config.soloist_input_src.do_name = 'multiplexer';
config.soloist_input_src.init_source = 'teensy';
config.soloist_input_src.teensy = 1;


config.zero_teensy.do_name      = 'zero_teensy';

config.trigger_input.init_source = 'from_soloist'; % 'from_soloist' or 'from_teensy'

config.position.deadband        = 0.1; % (cm/s) only integrate values > this to assess position

config.plotting                 = plotting_config();

