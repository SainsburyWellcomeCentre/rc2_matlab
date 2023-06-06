Teensy Usage
============

The ``rc2\teensy_ino`` directory contains `.ino` scripts and library `.c` files for loading onto a Teensy 3.2, to measure the velocity of a rotary encoder.

Setup
-----

To upload `.ino` scripts onto the Teensy, install Arduino (https://www.arduino.cc/en/software) and Teensyduino software
(https://www.pjrc.com/teensy/td_download.html). (Hint: make sure the Arduino software version is compatible with the Teensyduino version).

Next, the directories in `libraries` must be findable by the Arduino software. Currently, we do this by moving all of these directories into the Arduino libraries directory. (e.g.
``C:\Users\<user>\Documents\Arduino\libraries``). (TODO: this could be made more automatic).

.ino Scripts
------------

The following .ino scripts are available:

`forward_only.ino`

Measures the velocity of a treadmill attached to a rotary encoder and outputs the velocity as an analog output. 
Only outputs velocity in one direction. 

`forward_and_backward.ino`

Measures the velocity of a treadmill attached to a rotary encoder and outputs the velocity as an analog output. 
Outputs velocity in both directions, forward and backward.

`forward_only_variable_gain.ino`

Measures the velocity of a treadmill attached to a rotary encoder and outputs the velocity as an analog output. 
Only outputs velocity in one direction.
When a digital input goes high, the gain between the velocity recorded from the rotary encoder and the velocity output
on the analog output is changed.

The following are less frequently used:

`calibrate_soloist.ino`

Waits for a trigger input. When received outputs a command voltage corresponding to 400mm/s for 1 second.
Used with the Soloist Scope to calibrate the 'gear scale' parameter.

`single_level.ino`

Outputs single voltage on pin A14.

Options
-------

The `options.h` file in the `libraries` directory contains the shared options for the operation of the `.ino` scripts.

`FORWARD_DISTANCE` - the Teensy code contains an internal variable which records the distance the rotary encoder has moved. 
When the variable reaches this value in the "forward" direction (in millimeters) the variable is reset to zero.
A trigger is output upon reaching this value.

`BACKWARD_DISTANCE` - See `FORWARD_DISTANCE`. When the position variable reaches this value in the "backward" direction (in millimeters) the variable is reset to zero.

`FILTER_ON` - boolean, whether to filter the velocity with a sliding average window. If set to true, the value in `N_MILLIS_LOW` is used to determine the width of the sliding window.

`VARIABLE_WINDOW` - boolean, whether to reduce the size of the sliding window as the velocities increase. 
NOT RECOMMENDED TO SET TO 1 AS IT IS UNTESTED.

`N_MILLIS_LOW` - if `FILTER_ON` is 1, size of the sliding window to apply to the velocity trace in milliseconds.

`UPDATE_US` - if `FILTER_ON` is set to 1, then this determines how often the filtering is performed on the velocity trace, in microseconds.

`MAX_VELOCITY` - maximum velocity to output in mm/s.

`MAX_VOLTS` - the analog voltage output at `MAX_VELOCITY` in volts.

`DUAL_TRIGGER` - boolean, whether to use both the A and B ticks of the rotary encoder to calculate velocity.

`TIMEOUT` - duration in milliseconds to wait before velocity is set to zero after no motion detected on the rotary encoder.

`NM_PER_COUNT` - distance (in nanometers) the *treadmill* moves on each encoder tick (i.e. A-to-A or B-to-B). This depends on the size of the barrel used for the treadmill.

`PHASE_FACTOR` - value between 0 and 1, fraction of distance from A to B relative to distance from A to A. Empirically determined, as it does not seem to be exactly 0.25 or 0.5.

`PHASE_FACTOR_BACK` - value between 0 and 1, fraction of distance from A to B relative to distance from A to A. Empirically determined, as it does not seem to be exactly 0.25 or 0.5.

`ENC_A_PIN` - digital pin to use for the A tick of the encoder

`ENC_B_PIN` - digital pin to use for the B tick of the encoder

`ZERO_POSITION_PIN` - digital pin as input to use to reset the position variable to zero

`REWARD_PIN` - digital pin as output to use to send a signal when the position variable has reached `FORWARD_DISTANCE`
(Name does not reflect its function).

`DISABLE_PIN` - digital pin as input to use to stop outputting a voltage value representing velocity. 
Voltage output remains at `dac_offset_volts` (public property of Controller class)

.. note::
    The following apply to `forward_only_variable_gain.ino`, and overwrite the use of `ZERO_POSITION_PIN` and `REWARD_PIN`.

`GAIN_UP_PIN` - digital pin as input to use in `forward_only_variable_gain.ino` which tells the Teensy to increase the gain between
rotary encoder/treadmill velocity and analog voltage output.

`GAIN_DOWN_PIN` - digital pin as input to use in `forward_only_variable_gain.ino` which tells the Teensy to decrease the gain between
rotary encoder/treadmill velocity and analog voltage output.

`GAIN_UP_VAL` - gain value to apply between treadmill velocity and voltage output when the digital input to
the `GAIN_UP_PIN` is high.

`GAIN_DOWN_VAL` - gain value to apply between treadmill velocity and voltage output when the digital input to
the `GAIN_DOWN_PIN` is high. 

`GAIN_REPORT_PIN` - digital pin as output to use in `forward_only_variable_gain.ino` to indicate when the gain is changed from or to 1. 
(Strictly the state of this pin is changed before the ramp up or down of gain, so if gain is returning to 1, this pin will be low indicating
no gain change, when actually the gain will still not be 1 for another (`GAIN_UP_VAL`-1)*`MS_PER_UNIT_GAIN` or (1-`GAIN_DOWN_VAL`)*`MS_PER_UNIT_GAIN` milliseconds).

.. note::
    If both the `GAIN_UP_PIN` and `GAIN_DOWN_PIN` are high, a gain of 1 is applied.

.. note:: 
    The following are for internal usage, don't modify:

`DAC_PIN` - only option is `A14`, the DAC pin for analog output voltage

`MAX_DAC_VOLTS` - 3.3V, the maximum analog voltage output of the Teensy 

`MAX_DAC_BITS` - 4095, max 12-bit integer output on DAC pin

.. note::
    A voltage offset is applied on all scripts reporting velocity (`forward_only.ino`, `forward_and_backward.ino` and `forward_only_variable_gain.ino`). This value is set in the main `.ino` file during `setup()` as the `dac_offset_volts` property of the controller (currently 0.5V and this hasn't been changed). 