% Runs through calibration of offsets on various devices of the setup.
%
%   Offset routes:
%
%   1. Teensy   -> NIDAQ AI
%   2. Teensy   (-> Multiplexer) -> Soloist AI
%   3. NIDAQ AO (-> Multiplexer) -> Soloist AI
%   4. Teensy   (-> Multiplexer) -> Vis stim comp
%   5. NIDAQ AO (-> Multiplexer) -> Vis stim comp  
%   6. Raw teensy -> NIDAQ AI
%   7. Soloist -> NIDAQ AI


% options
max_velocity = 1000;     % mm/s
max_voltage = 2.5;       % V
cnts_per_unit = 10000;   %

% compute the theoretical gear scale
max_speed_scale = (max_velocity * cnts_per_unit)/1000;
theoretical_gear_scale = -(max_speed_scale * (1/max_voltage));

% create measure
cal = Calibrate(ctl);

% Nominal voltage on the analog output of the Teensy when at rest
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
% Along each column we have:
%      Solenoid    Gear mode
%   1. up          on
%   2. up          off
%   3. down        on
%   4. down        off
% Along the rows we have the 7 offset routes listed above
offset_error_mtx = nan(4, 7);



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
data = cal.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid UP, gear mode OFF here...\n')
input('Press Enter when done');

% Index of the filtered teensy input
filtered_idx = strcmp(ctl.ni.ai.channel_names, 'filtered_teensy');
%raw_idx = strcmp(ctl.ni.ai.channel_names, 'raw_teensy');                    % !!! For some reason, this is not called 'raw_teensy', but 'filtered_teensy_2'
raw_idx = strcmp(ctl.ni.ai.channel_names, 'filtered_teensy_2');
stage_idx = strcmp(ctl.ni.ai.channel_names, 'stage');

% Get the filtered teensy trace
filtered_trace = data(:, filtered_idx);
raw_trace = data(:, raw_idx);
stage_trace = data(:, stage_idx);

% Calculate main teensy offset
filtTeensy2ni_offset = mean(filtered_trace);
rawTeensy2ni_offset = mean(raw_trace);
stage2ni_offset = mean(stage_trace);

% Calculate and store the error in volts
offset_error_mtx(2, 1) = filtTeensy2ni_offset - teensy_stationary_V;
offset_error_mtx(2, 6) = rawTeensy2ni_offset;
offset_error_mtx(2, 7) = stage2ni_offset;

% compute the minimum deadband from this trace
minimum_deadband = max(abs(filtered_trace - filtTeensy2ni_offset));

% Plot the results
figure;
plot(filtered_trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')



% Message
fprintf('Calibrating Teensy to NI, solenoid DOWN, gear mode OFF...\n')

% Now set the solenoid down
ctl.treadmill.unblock()

% Collect some data on the NIDAQ
data = cal.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid DOWN, gear mode OFF here...\n')
input('Press Enter when ready');

% Get the filtered teensy trace
filtered_trace = data(:, filtered_idx);
raw_trace = data(:, raw_idx);
stage_trace = data(:, stage_idx);

% Calculate main teensy offset
filtTeensy2ni_offset1 = mean(filtered_trace);
rawTeensy2ni_offset1 = mean(raw_trace);
stage2ni_offset1 = mean(stage_trace);

% Calculate and store the error in volts
offset_error_mtx(4, 1) = filtTeensy2ni_offset1 - teensy_stationary_V;
offset_error_mtx(4, 6) = rawTeensy2ni_offset1;
offset_error_mtx(4, 7) = stage2ni_offset1;

% Plot the results
figure;
plot(filtered_trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid up')





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 2:  Teensy to Soloist (Gear mode ON) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to Soloist, solenoid UP (gear mode ON)...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid up
ctl.treadmill.block()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(1, 2) = relative_filtTeensy2soloist_offset * 1e-3;

% Message
fprintf('Calibrating Teensy to Soloist, solenoid DOWN (gear mode ON)...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(3, 2) = relative_filtTeensy2soloist_offset * 1e-3;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 2B:  Teensy to Soloist (Gear mode OFF) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to Soloist, solenoid UP (gear mode OFF)...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid up
ctl.treadmill.block()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV, true);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(2, 2) = relative_filtTeensy2soloist_offset * 1e-3;

% Message
fprintf('Calibrating Teensy to Soloist, solenoid DOWN (gear mode OFF)...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_filtTeensy2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV, true);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(4, 2) = relative_filtTeensy2soloist_offset * 1e-3;








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 3:  Teensy to NI: Gear mode ON %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to NI, solenoid UP, gear mode ON...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Put the solenoid up
ctl.treadmill.block()

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = -(teensy_stationary_mV + 1e3 * offset_error_mtx(1, 2));  %%%%%%%%%%%%%%

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Collect some data on the NIDAQ
data = cal.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid UP, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()
ctl.soloist.reset_pso();

% select the location of the max
filtered_trace = data(:, filtered_idx);
raw_trace = data(:, raw_idx);
stage_trace = data(:, stage_idx);

% main teensy offset on PC... step 1 done.
filtTeensy2ni_offset = mean(filtered_trace);
rawTeensy2ni_offset = mean(raw_trace);
stage2ni_offset = mean(stage_trace);

% Calculate and store the error in volts
offset_error_mtx(1, 1) = filtTeensy2ni_offset - teensy_stationary_V;
offset_error_mtx(1, 6) = rawTeensy2ni_offset;
offset_error_mtx(1, 7) = stage2ni_offset;

% Plot the results
figure;
plot(filtered_trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')



% Message
fprintf('Calibrating Teensy to NI, solenoid DOWN, gear mode ON...\n');

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Put the solenoid down
ctl.treadmill.unblock()

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = -(teensy_stationary_mV + 1e3 * offset_error_mtx(3, 2));  %%%%%%%%%%%%%%

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Collect some data on the NIDAQ
data = cal.measure();

% Wait for user input
fprintf('Can calibrate Teensy to Vis Stim, solenoid DOWN, gear mode ON here...\n');
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()
ctl.soloist.reset_pso();

% select the location of the max
filtered_trace = data(:, filtered_idx);
raw_trace = data(:, raw_idx);
stage_trace = data(:, stage_idx);

% main teensy offset on PC... step 1 done.
filtTeensy2ni_offset = mean(filtered_trace);
rawTeensy2ni_offset = mean(raw_trace);
stage2ni_offset = mean(stage_trace);

% Calculate and store the error in volts
offset_error_mtx(3, 1) = filtTeensy2ni_offset - teensy_stationary_V;
offset_error_mtx(3, 6) = rawTeensy2ni_offset;
offset_error_mtx(3, 7) = stage2ni_offset;

% Plot the results
figure;
plot(filtered_trace); xlabel('Sample point'); ylabel('Volts')
title('Teensy to NI, solenoid down')







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 4:  NI to Soloist %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating NI to Soloist, solenoid UP, gear mode ON...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

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
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(1, 3) = relative_ni2soloist_offset * 1e-3;


% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = -(teensy_stationary_mV + 1e3 * offset_error_mtx(1, 3));

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid UP, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()
ctl.soloist.reset_pso();

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid UP, gear mode OFF here...\n')
input('Press Enter when ready');



% Message
fprintf('Calibrating NI to Soloist, solenoid DOWN, gear mode ON...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_ni2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(3, 3) = relative_ni2soloist_offset * 1e-3;

% Set the AI offset on the solenoid to the "correct" value for this
% situtation. Convert to mV
ctl.soloist.ai_offset = -(teensy_stationary_mV + 1e3 * offset_error_mtx(3, 3)); %%%%%%%%%%%%

% Put the soloist in gear mode, do not wait for a trigger to start
ctl.soloist.listen_until(stage_middle+200, stage_middle-200, false);

% Wait a bit to setup the communication to soloist
pause(5);

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid DOWN, gear mode ON here...\n')
input('Press Enter when ready');

% Stop gear mode
ctl.soloist.stop()
ctl.soloist.reset_pso();

% Wait for user input
fprintf('Can calibrate NI to Vis Stim, solenoid DOWN, gear mode OFF here...\n')
input('Press Enter when ready');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 4B:  NI to Soloist (Gear mode OFF) %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating NI to Soloist, solenoid UP, gear mode OFF...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the multiplexer to listen to the Teensy
ctl.multiplexer.listen_to('ni');

% Put the solenoid up
ctl.treadmill.block()

% Set voltage on soloist equal to 'teensy_stationary_V'
ctl.ni.ao.idle_offset = teensy_stationary_V;

% Perform the setting of voltage
ctl.ni.ao.set_to_idle();

% Run calibration to determine offset on soloist
relative_ni2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV, true);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(2, 3) = relative_ni2soloist_offset * 1e-3;


% Message
fprintf('Calibrating NI to Soloist, solenoid DOWN, gear mode OFF...\n')

% Move to middle of stage
proc = ctl.soloist.move_to(stage_middle);

% Wait for move to complete.
proc.wait_for(0.5);

% Set the solenoid down
ctl.treadmill.unblock()

% Run calibration to determine offset on soloist
relative_ni2soloist_offset = ctl.soloist.calibrate_zero(stage_middle+100, stage_middle-100, -teensy_stationary_mV, true);

% Stop gear mode
ctl.soloist.stop()

% Store the error as volts
offset_error_mtx(4, 3) = relative_ni2soloist_offset * 1e-3;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 5:  Teensy to NI SCALES %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Teensy to NI *scale*, solenoid DOWN, gear mode OFF...\n')

% Set the multiplexer to listen to the Teensy
ctl.multiplexer.listen_to('teensy');

% Set the solenoid down
ctl.treadmill.unblock()

% print message to user
input('CALIBRATION: Move the treadmill as fast as possible in the next 10s. Press enter to start.\n');

% measure some data
data = cal.measure();

% select the location of the max
filtered_trace = data(:, filtered_idx);
raw_trace = data(:, raw_idx);

% print message to user
fprintf('Place box over part of trace to average:\n');

h_fig = figure;
plot(filtered_trace)
xlabel('Sample point')
ylabel('Volts')

rect = drawrectangle();

uans = input('Press enter key when happy with position (press N to exit):');

if strcmp(uans, 'N')
    return
end

coords = rect.Position;
idx1 = round(coords(1));
idx2 = round(idx1+coords(3));

close(h_fig);

% main teensy offset on PC... step 1 done.
filtTeensy2ni_max = mean(filtered_trace(idx1:idx2));
rawTeensy2ni_max = mean(raw_trace(idx1:idx2));

% compute the scale in cm
filtTeensy2ni_scale = max_velocity/(filtTeensy2ni_max - filtTeensy2ni_offset1)/10;
rawTeensy2ni_scale = max_velocity/(rawTeensy2ni_max - rawTeensy2ni_offset1)/10;

fprintf('Filtered teensy scale:  %.6f cm/s\n', filtTeensy2ni_scale);
fprintf('Raw teensy scale:  %.6f cm/s\n', rawTeensy2ni_scale);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 6:  Soloist to NI SCALES %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Message
fprintf('Calibrating Soloist to NI *scale*, solenoid DOWN (gear mode ON)...\n')

% 
target_velocity = 400; % mm/s

% move to back of stage. wait for move to complete
proc = ctl.soloist.move_to(1200); % needs to be configurable
proc.wait_for(0.5);

% load a calibration script onto the teensy
% it waits for a signal to start
ctl.teensy.load('calibrate_soloist')

% unblock the treadmill
ctl.treadmill.unblock()

% set the correct offset and scale on the soloist
ctl.soloist.ai_offset = -(teensy_stationary_mV + 1e3 * offset_error_mtx(3, 2));
ctl.soloist.set_gear_scale(theoretical_gear_scale);

% put stage into gear mode, don't wait for trigger
ctl.soloist.listen_until(1450, 400, false);

input('Ready to move (press Enter)?');

% Tell the teensy to start the profile
ctl.zero_teensy.zero();

% measure 10s of data
data = cal.measure();

% stop the soloist running
ctl.soloist.stop()
ctl.soloist.reset_pso();

stage_trace = data(:, stage_idx);

% print message to user
fprintf('Place box over part of trace to average:\n');

h_fig = figure;
plot(stage_trace)
xlabel('Sample point')
ylabel('Volts')

rect = drawrectangle();

uans = input('Press enter key when happy with position (press N to exit):');

if strcmp(uans, 'N')
    return
end

coords = rect.Position;
idx1 = round(coords(1));
idx2 = round(idx1+coords(3));

close(h_fig);

% main teensy offset on PC... step 1 done.
soloist2ni_max = mean(stage_trace(idx1:idx2));

% compute the scale in cm
soloist2ni_scale = target_velocity/(soloist2ni_max - stage2ni_offset1)/10;

fprintf('Soloist scale:  %.6f cm/s\n', soloist2ni_scale);


return

% Insert values from Vis Stim computer here....




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 7:  SAVE %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% store and save
calibration.channel_names = ctl.ni.ai.channel_names;

calibration.offset = zeros(1, length(ctl.ni.ai.channel_names));
calibration.scale = ones(1, length(ctl.ni.ai.channel_names));

calibration.offset(filtered_idx) = filtTeensy2ni_offset1;
calibration.offset(raw_idx) = rawTeensy2ni_offset1;
calibration.offset(stage_idx) = stage2ni_offset1;

calibration.scale(filtered_idx) = filtTeensy2ni_scale;
calibration.scale(raw_idx) = rawTeensy2ni_scale;
calibration.scale(stage_idx) = soloist2ni_scale;

calibration.gear_scale = theoretical_gear_scale;

calibration.nominal_stationary_offset = teensy_stationary_V;
calibration.offset_error_mtx = offset_error_mtx;
calibration.deadband_V = minimum_deadband;

save('calibration.mat', 'calibration');