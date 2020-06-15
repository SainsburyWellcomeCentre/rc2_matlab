% Runs through calibration of offsets on various devices of the setup.
%
%   Offset routes:
%
%   1. Teensy   -> NIDAQ AI
%   2. Teensy   (-> Multiplexer) -> Soloist AI
%   3. NIDAQ AO (-> Multiplexer) -> Soloist AI
%   4. Teensy   (-> Multiplexer) -> Vis stim comp
%   5. NIDAQ AO (-> Multiplexer) -> Vis stim comp  




% Voltage on the analog output of the Teensy when at rest
teensy_stationary_V = 0.5;

% Same voltage in mV
teensy_stationary_mV = 1e3 * teensy_stationary_V;

% Load 'forward_only' script on the Teensy (it shouldn't matter too much
% which script is loaded
ctl.teensy.load('forward_only');

% Calculate position of middle of stage
stage_middle = mean(ctl.soloist.max_limits);

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Create a matrix to store the offset errors (from teensy_stationary_V)
% Along the columns we have:
%      Solenoid    Gear mode
%   1. up          on
%   2. up          off
%   3. down        on
%   4. down        off
% Along the rows we have the 5 offset routes listed above
error_V = nan(4, 5);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 1:  Teensy to NI: Gear mode off %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to NI, solenoid UP, gear mode OFF...\n')

% Set the multiplexer to listen to the Teensy
ctl.multiplexer.listen_to('teensy');

% Put the solenoid up
ctl.treadmill.block()

% Collect some data on the NIDAQ
data = Calibrate.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid UP, gear mode OFF here...\n')
input('Press Enter when done');

% Index of the filtered teensy input
filtered_idx = strcmp(ctl.config.nidaq.ai.channel_names, 'filtered_teensy');

% Get the filtered teensy trace
trace = data(:, filtered_idx);

% Calculate main teensy offset
filtTeensy2ni_offset = mean(trace);

% Calculate and store the error in volts
error_V(2, 1) = filtTeensy2ni_offset - teensy_stationary_V;

% Plot the results
figure;
plot(trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')



% Message
fprintf('Calibrating Teensy to NI, solenoid DOWN, gear mode OFF...\n')

% Now set the solenoid down
ctl.treadmill.unblock()

% Collect some data on the NIDAQ
data = Calibrate.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid DOWN, gear mode OFF here...\n')
input('Press Enter when ready');

% Index of the filtered teensy input
filtered_idx = strcmp(ctl.config.nidaq.ai.channel_names, 'filtered_teensy');

% Get the filtered teensy trace
trace = data(:, filtered_idx);

% Calculate main teensy offset
filtTeensy2ni_offset = mean(trace);

% Calculate and store the error in volts
error_V(2, 1) = filtTeensy2ni_offset - teensy_stationary_V;

% Plot the results
figure;
plot(trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid up')





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 2:  Teensy to Soloist %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to Soloist, solenoid UP (gear mode ON)...\n')

% Set the solenoid up
ctl.treadmill.block()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
error_V(2, 2) = -relative_filtTeensy2soloist_offset * 1e-3;


% Message
fprintf('Calibrating Teensy to Soloist, solenoid DOWN (gear mode ON)...\n')

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
error_V(4, 2) = -relative_filtTeensy2soloist_offset * 1e-3;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 3:  Teensy to NI: Gear mode ON %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to NI, solenoid UP, gear mode ON...\n')

% Put the solenoid up
ctl.treadmill.block()

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = 1e3 * error_V(2, 2);

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Collect some data on the NIDAQ
data = Calibrate.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid UP, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()

% index of the filtered teensy
filtered_idx = strcmp(ctl.config.nidaq.ai.channel_names, 'filtered_teensy');

% select the location of the max
trace = data(:, filtered_idx);

% main teensy offset on PC... step 1 done.
filtTeensy2ni_offset = mean(trace);

% Calculate and store the error in volts
error_V(1, 1) = filtTeensy2ni_offset - teensy_stationary_V;

% Plot the results
figure;
plot(trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')


% Message
fprintf('Calibrating Teensy to NI, solenoid DOWN, gear mode ON...\n');

% Put the solenoid down
ctl.treadmill.unblock()

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = 1e3 * error_V(4, 2);

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Collect some data on the NIDAQ
data = Calibrate.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid DOWN, gear mode ON here...\n');
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()

% index of the filtered teensy
filtered_idx = strcmp(ctl.config.nidaq.ai.channel_names, 'filtered_teensy');

% select the location of the max
trace = data(:, filtered_idx);

% main teensy offset on PC... step 1 done.
filtTeensy2ni_offset = mean(trace);

% Calculate and store the error in volts
error_V(3, 1) = filtTeensy2ni_offset - teensy_stationary_V;

% Plot the results
figure;
plot(trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 4:  NI to Soloist %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating NI to Soloist, solenoid UP, gear mode ON...\n')

% Set the multiplexer to listen to the Teensy
ctl.multiplexer.listen_to('ni');

% Put the solenoid up
ctl.treadmill.block()

% Set voltage on soloist equal to 'teensy_stationary_V'
ctl.ni.ao.idle_offset = teensy_stationary_V;

% Perform the setting of voltage
ctl.ni.ao.set_to_idle();

% Run calibration to determine offset on soloist
relative_ni2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
obj.soloist.stop()

% Store the error as volts
error_V(2, 3) = -relative_ni2soloist_offset * 1e-3;


% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = 1e3 * error_V(2, 3);

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid UP, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid UP, gear mode OFF here...\n')
input('Press Enter when ready');



% Message
fprintf('Calibrating NI to Soloist, solenoid DOWN, gear mode ON...\n')

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_ni2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
error_V(4, 3) = -relative_ni2soloist_offset * 1e-3;

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = 1e3 * error_V(4, 3);

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid DOWN, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid DOWN, gear mode OFF here...\n')
input('Press Enter when ready');




