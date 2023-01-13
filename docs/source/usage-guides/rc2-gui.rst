Rollercoaster GUI
=================

The code comes with a small gui for easy access to some of the features of the setup.

It is suggested to read the other READMEs before using features on the GUI.

Panels
------

Stage
^^^^^

    `Position` edit box
    
    Determines the position on the stage moved to when the "MOVE TO" button is pushed. Units are in Soloist user units (see Soloist documentation for what this means).

    `Speed` edit box

    Determines the speed the stage moves to `Position` when the "MOVE TO" button is pushed. Units are in Soloist user units (see Soloits documentation for what this means).

    `MOVE TO` button

    Commands the stage to move to `Position` at speed `Speed`

    `HOME` button

    Homes the stage if it has not been homed already. If it has been homed, this button will have no  effect. If you want to re-home the stage, you should use the Soloist Motion Composer.

    `RESET` button

    Resets the parameters `GearCamSource`, `GearCamScaleFactor`, `GearCamAnalogDeadband`, `GainKPos` to their defaults and moves the stage to its "default" position. 

    The "default" values are set in ``<top_directory>\soloist_c\src\options.h`` (or ``<top_directory>\soloist_c\src\rc_soloist.h`` in older versions) as:
    
    - `DEFAULT_POSITION` - default position of the stage
    - `DEFAULT_GEARSOURCE` - default `GearCamSource` value
    - `DEFAULT_GEARSCALEFACTOR` - default `GearCamScaleFactor` value
    - `DEFAULT_ANALOGDEADBAND` - default `GearCamAnalogDeadband` value
    - `DEFAULT_GAINKPOS` - default `GainKPos` value

    See the official Soloist documentation for exactly what these parameters do.

    `STOP` button

    Forces abort of the current executing program on the Soloist. *Do not use for normal ending of training or experiments.* This is meant as a backup in case of unusual behaviour on the stage.

Training
^^^^^^^^

    `START TRAINING` button

    Starts a "training" session. 
    A training sessions consists of a sequence of trials at the end of which the animal gets a reward.
    The trials can either be `Coupled` or `EncoderOnly` types (see README in protocols section for details of these trial types).
    To run a sequence of `Coupled` trials (i.e. the stage velocity is matched to the treadmill velocity), the `Closed loop` radio button should be selected.
    To run a sequence of `EncoderOnly` trials (i.e. the treadmill can move but there is no movement of the stage), the `Open loop` radio button should be selected.
    The other details of the trials are determined by the other  UI elements in this panel.

    After starting the same button says `STOP TRAINING`, and can be used to stop the training session.
    Sometimes it can take some time before the trial is acqually stopped, for instance is the stage is currently in motion or a calibration is occurring.

    `Reward location` edit box

    If `Closed loop` toggle button is selected, this is the position on the stage at which trials are stopped and a reward is given.
    In either `Closed loop` or `Open loop` cases, this value together with `Reward distance`  determines the position of the stage at the start of the trial.


    `Reward distance` edit box

    Distance the treadmill/stage should move before a reward is given. 
    In either Closed loop or Open loop cases, this value together with `Reward location` determines the position of the stage at the start of the trial.

    The start of the trial for both `Closed loop` and `Open loop` is computed from `Reward location` and `Reward distance` as: `start location = Reward location + Reward distance`.

    `Forward only` tick box

    If selected the `forward_only.ino` script is loaded onto the Teensy. 
    This just outputs velocities corresponding to forward motion of the treadmill.
    If unselected the `forward_and_backward.ino` script is loaded onto the Teensy.
    This outputs velocities for both forward and backward motion of the treadmill.

    `Trial #` box

    Not settable. Reports the current trial which is being performed.

    `# forward:` text

    Reports the number of previous trials which have ended with the treadmill/stage moving to the forward position.

    `# backward:` text

    Reports the number of previous trials which have ended with the treadmill/stage moving to the backward position.

    `Closed loop` toggle box

    If selected, runs a sequence of `Coupled` trials in which the stage velocity is controlled by the treadmill motion.

    `Open loop` toggle box

    If selected, runs a sequence of `EncoderOnly` trials in which the treadmill can move but the stage is stationary.

Experiment
^^^^^^^^^^

    Experiment protocols (i.e. sequences of arbitrary trials) can be selected using this panel.
    The `...` push button opens a UI in which a file containing an experiment protocol can be selected.
    The currently selected file is shown in the text box to the side.

    The `.m` file selected must have a specific format (see `Experiment File`_ below.)

    To start the trial sequence returned by the file, the `START EXPERIMENT` push button is pressed.

    After starting the same button says `STOP EXPERIMENT`, and can be used to stop the experiment.
    Sometimes it can take some time before the trial is acqually stopped, for instance is the stage is currently in motion or a calibration is occurring.

    The number of the currently executing trial is reported in the `Trial #` text box. 

    Saving

    If `START_TRAINING` or `START_EXPERIMENT` push buttons are pressed, and the `Save` checkbox is selected, data on the NIDAQ analog inputs will be acquired and logged.

    This panel determines where that data will be saved.

    To select the `<root_dir>` in which data will be saved press the `...` push button.
    This opens a UI in which a "root" directory on the system can be selected into which to put the logged data.

    The `Prefix` and `Suffix` edit boxes can be used to specify further where data will be saved. 
    The `Index` text box cannot be edited but, when either the `<root_dir>` or the `Prefix` or `Suffix` boxes are edited, the value in `Index` goes back to `1`.
    After this, if `START_TRAINING` or `START_EXPERIMENT` are pushed and `Save` is selected, then upon stopping the trial or experiment, the value in `Index` is iterated to the next integer.

    So, if the root directory is `<root_dir>`, and the string in `Prefix` is `foo`, the string in `Suffix` is `bar`, and the integer in `Index` is `N`, then the next acquisition will log data to:

        ``<root_dir>\foo\foo_bar_%03N.bin``

    where the `%03N` indicates that the string at the end is 0 padded and of length 3.

    Furthermore, an associated configuration file with the same name extention `.cfg` is saved alongside the `.bin` file.

Treadmill
^^^^^^^^^

    `BLOCK` button

    Blocks the treadmill by sending the solenoid high.

    `UNBLOCK` button

    Unblocks the treadmill by sending the solenoid low.

Pump
^^^^

    `ON` button

    Turns the pump on continuously.

    `OFF` button

    Turns the pump off continuously.

    `REWARD` button

    Provides a reward by turning the pump on for `Duration` milliseconds.

    `Duration` edit box

    Determines the duration in milliseconds the pump is on when the `REWARD` button is pressed.

Sound
^^^^^

    `PLAY` push button.

    Plays a sound if the `Enable` toggle button is selected. Also used to `STOP` the sound. The sound can be stopped if `Disable` toggle button is selected.

AI Preview
^^^^^^^^^^

    The `PREVIEW` button starts acquiring and displaying the analog input data in real time but does not log the data. 
    The same button is used to stop previewing the data.

    See :class:`rc.aux_.Plotting` for description of the display handled by :class:`rc.main.Controller`.

Experiment file
---------------

The experiment file provided to the program in the `Experiment` panel must have a specific format. 
If we have selected ``path\to\experiment_file.m``
then `experiment_file.m` must be a function file on the MATLAB path with top line::


    function seq = experiment_file(ctl)


The function takes as argument `ctl`, the main controller object of :class:`rc.main.Controller`.
It returns an object `seq` of :class:`rc.prot.ProtocolSequence`, and this is the class which is run when `START_EXPERIMENT` is pressed.
(i.e. the `run` method of the `seq` object). 

The rest of the function file should describe a set of trial objects (:class:`rc.prot.Coupled`, :class:`rc.prot.EncoderOnly`, :class:`rc.prot.StageOnly` etc.), set their properties, and add them to a :class:`rc.prot.ProtocolSequence` object.

See the :doc:`rc2-protocols` documentation for more information on trials and protocol sequences.