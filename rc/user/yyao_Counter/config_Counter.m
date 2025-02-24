function config = config_Counter()




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General NIDAQ parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.rate                       = 10000;  % sampling rate of nidaq
config.nidaq.log_every                  = 1000;  % log data every number of samples



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG INPUT parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ai.enable                  = true;
config.nidaq.ai.dev                     = 'Dev1';  % device name
config.nidaq.ai.channel_names           = {'0'};  % nominal channel names (for reference)
config.nidaq.ai.channel_id              = [0];
config.nidaq.ai.offset                  = [0];  % 5.0
config.nidaq.ai.scale                   = [1];  % -1.6
config.offsets.enable                   = false;
config.offsets.error_mtx                = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALOG OUTPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.ao.enable                  = true;
config.nidaq.ao.dev                     = 'Dev1';
config.nidaq.ao.channel_names           = {'0'};
config.nidaq.ao.channel_id              = [0];
config.nidaq.ao.idle_offset             = [0];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUNTER OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.co.enable                  = true;
config.nidaq.co.dev                     = 'Dev1';
config.nidaq.co.channel_names           = {'camera'};
config.nidaq.co.channel_id              = 1;  % PFI13
config.nidaq.co.init_delay              = 0;
config.nidaq.co.pulse_high              = 60;
config.nidaq.co.pulse_dur               = 333;  % ms, e.g. 125 = 80Hz 333;%
config.nidaq.co.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL OUTPUT parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.do.enable                  = false;
config.nidaq.do.dev                     = 'Dev1';
config.nidaq.do.channel_names           = {'pump', 'visual_stimulus_start_trigger', 'waveform_peak_trigger'};
config.nidaq.do.channel_id              = {'port0/line0', 'port0/line1', 'port0/line2'};
config.nidaq.do.clock_src               = sprintf('/%s/ai/SampleClock', config.nidaq.ai.dev);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIGITAL INPUT parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nidaq.di.enable                  = false;
config.nidaq.di.dev                     = '';
config.nidaq.di.channel_names           = {};
config.nidaq.di.channel_id              = {};




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checks on config structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.channel_id));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.offset));
assert(length(config.nidaq.ai.channel_names) == length(config.nidaq.ai.scale));
