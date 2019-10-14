function config = load_config()


config.saving.save_to       = 'C:\Users\Mateo\Desktop\DefaultData';


config.stage.start_pos          = 750;
config.stage.back_limit         = 1450;
config.stage.forward_limit      = 250;
config.stage.ai_offset          = -28.0;


config.nidaq.rate               = 10000;
config.nidaq.log_every          = 1000;

config.nidaq.ai.dev             = 'Dev2';
config.nidaq.ai.channel_names   = {'filtered_teensy', 'lick', 'pump', 'stage', 'raw_teensy', 'solenoid', 'photodiode'};
config.nidaq.ai.channel_id      = 0:7;


config.nidaq.ao.dev             = 'Dev2';
config.nidaq.ao.channel_names   = {'velocity'};
config.nidaq.ao.channel_id      = 0;


config.nidaq.co.dev             = 'Dev2';
config.nidaq.co.channel_names   = {'camera'};
config.nidaq.co.channel_id      = 0;
config.nidaq.co.init_delay      = 0;
config.nidaq.co.pulse_high      = 100;
config.nidaq.co.pulse_dur       = 333;  % 30Hz
config.nidaq.co.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);


config.nidaq.do.dev             = 'Dev2';
config.nidaq.do.channel_names   = {'pump', 'multiplexer', 'solenoid'};
config.nidaq.do.channel_id      = {'port0/line0', 'port0/line1', 'port0/line2'};
config.nidaq.do.clock_src       = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);


config.teensy.exe               = 'C:\Program Files (x86)\Arduino\arduino_debug.exe';
config.teensy.dir               = '..\teensy_ino';
config.teensy.start_script      = 'forward_only';


config.soloist.dir              = '..\soloist_c\exe';


config.reward.do_name           = 'pump';
config.reward.randomize         = true;
config.reward.min_time          = 3;
config.reward.max_time          = 7;
config.reward.duration          = 50;


config.treadmill.do_name        = 'solenoid';
config.treadmill.init_state     = 1;


config.soloist_input_src.do_name        = 'multiplexer';
config.soloist_input_src.init_source    = 'teensy';
config.soloist_input_src.teensy         = 0;


config.plotting                 = plotting_config();

