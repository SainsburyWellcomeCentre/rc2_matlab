Rollercoaster Usage Overview
============================

.. note::
    WARNING: this repository contains code for moving two rotatory stages carrying large loads, which can move rapidly and unexpectedly. This may present a health hazard. You use this software at your own risk. The authors accept absolutely no responsibility for damage, injury or loss of life resulting from use of this software.

Rollercoaster Description
-------------------------

The code is for controlling the "rollercoaster" setup with two independent rotatory stages (referred to as
RC2DoubleRotation). This is a branch of RC2 software. Modifications are made in a newly created user folder
``<top_directory>\rc\user\yyao_DoubleRotation``. The code cooperates with visual stimuli code on another computer via 
Ethernet connection to drive the setup.

Hardware
--------

The software was written to control the following hardware:

1. An NI DAQ USB-6343
2. Two Aerotech rotatory stages (ADRT150-135 and ADRT260-160) with two Ensemble HLe controllers
3. A pump for reward 
4. A visual stimuli computer with Ethernet connection

These hardware features can be enabled or disabled in the config file (see `Configuration Files`_).

Installation
------------

This code has been developed on Windows 10 with MATLAB 2022b.

In order to use all hardware the following should be installed on the system:

1. Aerotech drivers for controlling the rotatory stages (Aerotech Ensemble v5.06.001, comes with controllers)
2. NI-DAQmx drivers

Configuration Files
-------------------

A template configuration file is in: 
- ``<top_directory>\rc\user\yyao_DoubleRotation\Main\configs\config_yyao.m``

where `<top_directory>` is the location on the system of this repository.  
This file should be copied and modified for the current setup.

Other configuration variables are contained in:

- ``<top_directory>\soloist_c\src\rc_soloist.h``
- ``<top_directory>\teensy_ino\libraries\options\options.h``

These files contain variables that are less often modified, but changing them requires extra steps to implement. 

If a variable in the `rc_soloist.h` file is changed, then some or all of the executables will need to be rebuilt and placed in ``<top_directory>\soloist_c\exe\``. 
To do that you can use the `build.bat` file in that directory.
If g++ is present on the Windows path then this will automatically put the 

If a variable in the Teensy `options.h` file is changed, then the `options.h` will have to be copied to the Arduino libraries directory.

Read the README files in the `soloist_c` and `teensy_ino` directories for further information.

Configuration
-------------

The configuration structure describes the setup.

A template file with the configuration options is in `config_template.m` in the ``main/configs`` directory.

The entries in this structure are:

`saving.save_to`

String describing the full path to the directory in which to save files

`saving.config_file`

String with the full path to the opening configuration file.

`saving.main_dir`

String with the full path to the rollercoaster directory.

`saving.single_trial_log_channel_name`

If saving data for a single trial, which analog input should be saved.

`saving.git_dir`

String with the full path to git directory tracking the rollercoaster directory

`stage.start_pos`

Passed to the trial classes, this defines the trial's default start position on the stage.

`stage.back_limit`

Passed to the trial classes, this defines the back-most position on the stage which terminates a trial if it is reached.

`stage.forward_limit`

Passed to the trial classes, this defines the front-most position on the stage which terminates a trial if it is reached.

`stage.max_limits`

2x1 vector describing the position of the [back, front] limits on the stage. 
Specifying a movement to a position beyond either of these positions is not allowed.

`nidaq.rate`

Sampling rate of the analog input and outputs on the NIDAQ

`nidaq.log_every`

Number of samples after which to run the callback functions. 

`nidaq.ai.enable`

`true` or `false` - whether to enable the analog input module.
Digital and counter outputs rely on the analog input module so they will not work if this is `false`.
Also, if this is `false` then there will be nothing to be saved.

`nidaq.ai.dev`

String, NI device name controlling the analog inputs (e.g. `'Dev1'`).

`nidaq.ai.channel_names`

1 x # AI channels cell array of strings.
Names to give to each analog input channel

`nidaq.ai.channel_id`

1 x # AI channels vector of integers.
NIDAQ channel ID of each analog input channel.

`nidaq.ai.offset`

1 x # AI channels vector of doubles.
Offset, in volts, to subtract from each analog input channel to make the baseline 0.

`nidaq.ai.scale`

1 x # AI channels vector of doubles.
Scale to apply to each analog input channel after offset subtraction to create sensible units for that channel.
In units of "final value / volts" (e.g. cm/s / V)

`nidaq.ao.enable`

`true` or `false` - whether to enable the analog output module.

`nidaq.ao.dev`
 
String, the device name controlling the analog outputs (e.g. `'Dev1'`).

`nidaq.ao.channel_names`

1 x # AO channels cell array of strings.
Names to give to each analog output channel
If there are two, then the second should be called 'delayed_velocity' and is expected to be a delayed copy of the first analog output channel.

`nidaq.ao.channel_id`

1 x # AO channels vector of integers.
NIDAQ channel ID of each analog output channel

`nidaq.ao.idle_offset`

1 x # AO channels vector of doubles.
Voltages at which each analog output should sit at baseline.
TODO: this is not used, but reset on each trial start. Remove.

`nidaq.co.enable`

`true` or `false` - whether to enable the counter output module.
If this is `true`, `nidaq.ai.enable` should also be `true` and setup with at least one channel.

`nidaq.co.dev`

String, the device name controlling the counter outputs (e.g. `'Dev1'`).

`nidaq.co.channel_names`

1 x # CO channels cell array of strings.
Names to give to each counter output channel.
Currently, code will only work with 1 channel, or if there are two each channel will do the same thing...

`nidaq.co.channel_id`

1 x # CO channels vector of integers
NIDAQ channel ID of each counter output channel 
(e.g. if `[0, 1]`, this will map onto `'ctr0'` and `'ctr1'`)

`nidaq.co.init_delay`

Integer, number of samples to wait before generating the first pulse

`nidaq.co.pulse_high`

Integer, number of samples that the pulse is high.

`nidaq.co.pulse_dur`

Integer, number of samples between the rise of each pulse.

`nidaq.co.clock_src`

String, terminal determining the timebase of the counter output (e.g. `'/Dev1/ai/SampleClock'`)

`nidaq.do.enable`

`true` or `false` - whether to enable the digital output module.
If this is `true`, `nidaq.ai.enable` should also be `true` and setup with at least one channel.

`nidaq.do.dev`

String, the device name controlling the digital outputs (e.g. `'Dev1'`).

`nidaq.do.channel_names`

1 x # DO channels cell array of strings.
Name to give to each digital output channel.

`nidaq.do.channel_id`

1 x # DO channels cell array of strings.
Port/line number of each digital output channel.
(e.g. `'port0/line0'`)

`nidaq.do.clock_src`

String, terminal determining the timebase of the digital output (e.g. `'/Dev1/ai/SampleClock'`)

`nidaq.di.enable`

`true` or `false` - whether to enable the digital input module.

`nidaq.di.dev`

String, the device name controlling the digital inputs (e.g. `'Dev1'`).

`nidaq.di.channel_names`

1 x # DI channels cell array of strings.
Names to give to each digital input channel

`nidaq.di.channel_id`

1 x # DI channels cell array of strings.
Port/line number of each digital output channel.
(e.g. `'port1/line0'`)
Note that digital inputs and digital outputs must be on different ports.
(i.e. once a port has a digital output/input all other lines on that port must be the same type)

`teensy.enable`

`true` or `false` - whether to enable the Teensy module.
If not enabled, no scripts will be loaded to the Teensy.

`teensy.exe`

String, full path to the Arduino executable file 
(e.g. `'C:\Program Files (x86)\Arduino\arduino_debug.exe'`)

`teensy.dir`

String, full path to the directory containing the folders with the .ino scripts and .c libraries.
(e.g. `''C:\Users\treadmill\Code\rc2_matlab\teensy_ino'`)

`teensy.start_script`

String, name of the `.ino` script to load onto the Teensy.

`soloist.enable`

`true` or `false` - whether to enable the Soloist module.
If not enabled, no commands are sent to the Soloist controller.

`soloist.dir`

String, full path to the directory containing the `ab`, `exe` and `src` folders for controlling the Soloist.

`soloist.default_speed`

Double, default speed of the stage during a 'move_to' operation.
Units are in Soloist user units. 
Refer to the Soloist documentation for more details on the values.

`soloist.v_per_cm_per_s`

Double, scale factor which specifies how many volts lead to a 1cm/s movement of the stage.
This is only used in one place in the code: 
for providing a ramp velocity command to the Soloist from of the NIDAQ analog output, if the stage does not reach the specified final location during a replay trial.
(i.e. `StageOnly`)

`soloist.ai_offset`

Double, in millivolts, the value to set the `Analog0InputOffset` parameter on the Soloist
to account for the baseline offset of the Teensy (so far 0.5V).
This value is set during calibration at the beginning of each trial (`Coupled`, `CoupedMismatch`, `StageOnly`)
so only takes effect after startup of the program.

`soloist.gear_scale`

Double, value applied to the `GearCamScaleFactor`, which determines the gain between voltage and speed of the stage.
It is very important that this value is set correctly.
If it is too high, then small voltages can lead to extremely rapid movements of the stage.
See Soloist documentation for proper description of `GearCamScaleFactor`.
See also Soloist README for another description.

`soloisit.deadband`

Double, in volts, value applied to the `GearCamAnalogDeadband` property.
See Soloist documentation for proper description of `GearCamAnalogDeadband`.
This determines the voltage below which no motion occurs on the stage.

`reward.randomize`

`true` or `false` - whether to enable the randomization of reward.
If `true` reward is provided between `reward.min_time` and `reward.max_time`.
If `false` rewards are given immediately (software timed).

`reward.min_time`

Double, in seconds, time to wait before giving any reward if `reward.randomize` is `true`.

`reward.max_time`

Double, in seconds, latest to wait before giving any reward if `reward.randomize` is `true`.

`reward.duration`

Double, in milliseconds, duration to pulse the pump to give the reward.

DEVICE PARAMETERS
^^^^^^^^^^^^^^^^^

The following are modules for controlling digital inputs and outputs to control certain devices on the setup.
They can all be enabled or disabled and have a "name".
This name should correspond to the name in the digital inputs and outputs description above.
(i.e. `nidaq.do.channel_names` and `nidaq.di.channel_names`)
to specify which digital line to use for controlling the device.
If any are enabled, the corresponding `nidaq.do.enable` or `nidaq.di.enable` module should be `true`.


Digital outputs 

`pump.enable`

`true` or `false` - whether to enable the pump module.

`pump.do_name`

String, name of the NIDAQ digital output channel to use to control the pump.
See also `nidaq.do.channel_names`

`pump.init_state`

`0` or `1` initial state of the pump.  `0` = digital output low, `1` = digital output high.
(There's little reason to start with the pump on, so this value should be `0`).

`treadmill.enable`

`true` or `false` - whether to enable the module controlling the solenoid block of the treadmill.

`treadmill.do_name`

String, name of the NIDAQ digital output channel to use to control the solenoid.
See also `nidaq.do.channel_names`

`treadmill.init_state`

`0` or `1` initial state of the solenoid.  `0` = solenoid low, `1` = solenoid high.

`soloist_input_src.enable`

`true` or `false` - whether to enable the module controlling the multiplexer (i.e. voltage input to the Soloist, hence the name)

`soloist_input_src.do_name`

String, name of the NIDAQ digital output channel to use to control the pump.
See also `nidaq.do.channel_names`

`soloist_input_src.init_source`

String, initial analog input source to transmit through the multiplexer. 
Should be one of `teensy` or `ni`.

`soloist_input_src.teensy`

`0` or `1` indicates whether when transmitting the Teensy analog voltage the digital input to the multiplexer should be low (`0`) or high (`1`).

`zero_teensy.enable`

`true` or `false` - whether to enable the module sending a pulse DO to the Teensy to zero the position.

`zero_teensy.do_name`

String, name of the NIDAQ digital output channel to use to send the signal to zero the internal Teensy position.
Note that whatever digital output is used, it should be connected to the 
pin described by ZERO_POSITION_PIN in the `<top_directory>\teensy_ino\libraries\options\options.h` file in the Teensy directory.
See also `nidaq.do.channel_names`

`disable_teensy.enable`

`true` or `false` - whether to enable the module sending a pulse DO to the Teensy to stop reporting the velocity of the treadmill (and sit at its baseline value). (Used during calibration of offsets at the beginning of each trial)

`disable_teensy.do_name`

String, name of the NIDAQ digital output channel to use to send the signal to zero the internal Teensy position.
Note that whatever digital output is used, it should be connected to the 
pin described by DISABLE_PIN in the `<top_directory>\teensy_ino\libraries\options\options.h` file in the Teensy directory.
See also `nidaq.do.channel_names`

`disable_teensy.init_state`

`0` or `1` initial state of the signal.  `0` = digital output low (velocity output allowed), `1` = digital output high (velocity output disabled).

`start_soloist.enable`

`true` or `false` - whether to enable the module sending a pulse DO to trigger events  on the soloist (such as starting a trial).

`start_soloist.do_name`

String, name of the NIDAQ digital output channel to use to send the signal to zero the internal Teensy position.
Note that whatever digital output is used, it should be connected to the 
`Digital Input 1` (pins 18/24 on the J205 of the Soloist controller).
See also `nidaq.do.channel_names`.

Startup
-------

To start up a GUI which can be used for elementary control of the setup, add the `<top_directory>` to the MATLAB path and start::

    >> rc2_startup;


Alternatively you can start the program at the command line by first loading the setup configuration::

    >> config = my_config_file();

And then passing this to the controller::

    >> ctl = RC2Controller(config);

At that point, you can either startup the GUI::

    >> gui = rc2guiController(ctl);


Or use any of the methods in the RC2Controller class directly, e.g.::

    >> ctl.pump_on

To close the program run::

    >> rc2_shutdown;

Saving
------

If the `enabled` property of the `Saver` class is true, then upon starting an acquisition with `Controller.start_acq` data will be logged during the acquisition.
When acquisition starts, the `Saver` class will check for any existing files in the log location and ask the user whether to overwrite.
It will also create any necessary directories and open a stream to an output .bin file and save the current configuration information to a .cfg file.

`CONFIG`

The `Saver` class logs configuration information as a .cfg file. The data takes the form of an Nx2 cell array. Each row of the cell array is of the form {<key>, <value>} giving the configuration of a parameter.

`DATA LOGGING`

Voltage data from the recorded analog input channels is logged to a .bin file. The data is first scaled to `int16` values and then stored as `int16` integers.

Creating Protocols
------------------

A *trial* on the setup involves the concept of motion with a start and end point. 
This could involve movement of the stage from the back to the front, running on the treadmill a certain distance (from unblocking the treadmill to blocking of the treadmill a certain distance later), or viewing a corridor which moves a certain distance (or combination of these).

A set of classes for implementing *trials* on the setup is already provided in ``<top_directory>\rc\prot``. These include:

- `Coupled`
- `EncoderOnly`
- `ReplayOnly`
- `StageOnly`
- `CoupledMismatch`
- `EncoderOnlyMismatch`

.. note:: 
    These names are not particularly descriptive, and ideally should be changed, but remain for historical reasons.

See the :doc:`rc2-protocols` guide for a description of each trial type.

In order to create a sequence of trials, the `ProtocolSequence` class can be used. 
This stores a sequence of trial objects in a cell array and executes them one after the other.

Teensy
------

Several `.ino` scripts are available to upload onto the Teensy 3.2 in ``<top_directory>\teensy_ino\``.  

These scripts rely on a set of library classes. Therefore, in order to upload the `.ino` files, the directories in ``<top_directory>\teensy_ino\libraries`` must be made available to the Arduino software. Currently this involves copying these directories to the `libraries` directory  of Arduino (located in e.g.
``C:\Users\<user>\Documents\Arduino\libraries``).

See the :doc:`rc2-teensy` for more information.

Soloist
-------

The commands for controlling the linear stage are located in ``<top_directory>\soloist_c``. Source C and C++ files are in a subdirectory `src` and executables are in `exe`. In addition there are Aerobasic scripts in `ab`.

See the :doc:`rc2-soloist` for more information.

Controller Classes
------------------

The :class:`rc.main.RC2Controller` class contains all the objects for interacting with different elements on the setup.

At startup you create the object by passing it a properly formed configuration structure (see `Configuration`_ above)::

    config = my_config();   % <---- where my_config.m is a file describing the configuration  
    ctl = RC2Controller(config);

Wiring
------

The `.m` configuration file describes the connections on the NIDAQ. 
The `options.h` file in the Teensy directory describes the connections from the Teensy.
The `rc_soloist.h` file in the Soloist `src` directory describes the connections from the Soloist.

Generally the exact pins on each device can be flexibly defined in the code. 
However, the code expects a certain wiring topology. 

Connections
^^^^^^^^^^^

In order to feed the velocity of the treadmill to the linear stage as well as log the velocity of the treadmill, 
the analog output of the Teensy is split to an analog input on the multiplexer (which then goes to the Soloist), and an analog input of the NIDAQ.

In order to play back the logged velocity on a trial, an analog output of the NIDAQ is sent to another analog input on the multiplexer.

A digital output is sent from the NIDAQ to the digital input of the multiplexer to determine which channel (Teensy or NIDAQ AO) is forwarded to the Soloist.

The analog output of the multiplexer is split twice and goes to:
- an analog input on the NIDAQ
- the analog input of the Soloist controller (controls stage velocity)
- the visual stimulus computer (to control motion of the virtual corridor)

A digital output controlling the state of the solenoid (i.e. treadmill block) is split twice and goes to:
- the solenoid controller
- an analog input on the NIDAQ
- a digital input (Digital Input 0 (pins 17/23 on the J205)) on the Soloist (TODO: make this digital input more flexible)

The PSO output of the Soloist controller is sent to a digital input on the NIDAQ to indicate that trials, where the stage is in motion, have ended.

Voltage Offsets
---------------

Teensy baseline effect
^^^^^^^^^^^^^^^^^^^^^^

When the treadmill is stationary, the Teensy outputs a voltage of 0.5V (to report both forward and backward movement where appropriate). 
However, due to the electronics on the setup, this is not the exact voltage seen by the Soloist controller and there will be a difference from this value (on the order of millivolts).
Furthermore, this difference has been observed to vary across days and depending on the state of the setup (wiring/which components are active etc.)

Therefore, to ensure that the stage does not move when the treadmill is stationary, we calibrate the analog input to the controller before each trial in which the analog input will control the velocity of the stage.
This involves measuring the analog input voltage on the Soloist controller just before the trial, then setting the `Analog0InputOffset` (`soloist.ai_offset` in the config) parameter to the negative of the measured value on the controller during the trial.

Solenoid
^^^^^^^^

The above calibration is performed when the solenoid is up (to prevent the treadmill from moving during calibration).
However, when the treadmill velocity is controlling the stage, the solenoid is down (e.g. during `Coupled` and `CoupledMismatch`).
The state of the solenoid (up or down) has an effect on the analog input voltage on the Soloist.
Therefore, we must apply an additional offset correction for when the Solenoid is down. 
Currently, this correction is applied by a property ``solenoid_correction`` of the :class:`rc.prot.Coupled` and :class:`rc.prot.CoupledMismatch` 

Difference between analog input and analog output on the NIDAQ
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In order to replay velocity waveforms we save one analog input channel on the NIDAQ (see `Saving`_)
This data is then loaded and output on the analog output. 

However, outputting the exact value read on the analog input of the NIDAQ on the analog output again leads to a slight difference in value observed by the Soloist (again a few millivolts).
Therefore, before outputting a saved voltage another offset is applied to the values in the data before being output (see docs :class:`rc.classes.Offsets`).
