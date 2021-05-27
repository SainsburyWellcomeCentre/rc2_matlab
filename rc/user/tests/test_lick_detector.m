config = config_empty();
ctl = RC2Controller(config);

n_seconds = 6;
rate = 10000;
n_samples_per_loop = 1000;
trigger_start = 3.0032;
trigger_duration = 0.5001;
lick_1_start = 3.1512;
lick_1_dur = 0.0135;
lick_2_start = 3.3982;
lick_2_dur = 0.2357;

config.lick_detect.enable = true;
config.lick_detect.n_windows = 5;
config.lick_detect.window_size_ms = 250;
config.lick_detect.n_lick_windows = 2;
config.lick_detect.lick_threshold = 2;
config.lick_detect.trigger_channel = 3;
config.lick_detect.lick_channel = 2;

% need to pretend AI is enabled and has a sampling rate
ctl.ni.ai.enabled = true;
ctl.ni.ai.task = FakeTask();
clt.ni.ai.task.Rate = rate;

lick_detect = LickDetect(ctl, config);
data = zeros(n_seconds*rate, 4);
data(round(trigger_start*rate) + (0:round(trigger_duration*rate)-1), config.lick_detect.trigger_channel) = 5;
data(round(lick_1_start*rate) + (0:round(lick_1_dur*rate)-1), config.lick_detect.lick_channel) = 5;
data(round(lick_2_start*rate) + (0:round(lick_2_dur*rate)-1), config.lick_detect.lick_channel) = 5;

figure, plot(data)
n_loops = floor(size(data, 1)/n_samples_per_loop);

%%
for i = 1 : n_loops
    
    start_sample_idx = (i-1)*n_samples_per_loop + 1;
    ctl.data = data(start_sample_idx + (0:n_samples_per_loop-1), :);
    lick_detected = lick_detect.loop();
    
    if lick_detected
        % indicate where the lick is detected
        data(start_sample_idx + n_samples_per_loop + (0:10), 4) = 10;
    end
end

figure, plot(data)
