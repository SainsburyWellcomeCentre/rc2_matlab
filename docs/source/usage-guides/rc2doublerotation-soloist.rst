Soloist Usage
=============

The ``rc2\soloist_c`` directory contains source C and C++ code in the directory `src`, as well as executables in `exe`. Further, Aerobasic scripts are contained in the `ab` directory.

.. warning::
    If used incorrectly this software could make the linear stage a health hazard. Use at your own risk.

.. warning::
    The behaviour of this software depends on the parameters set on the Soloist controller. See the Soloist help documents for official usage of the functions and parameters controlling the stage, do not rely on the following as an accurate description.

The most important point is that the `GearCamScaleFactor` is set appropriately. 
This parameter is responsible for converting an analog voltage input to the Soloist controller, into the velocity of the linear stage.

If `GearCamScaleFactor` is set too large, then small voltage deflections could lead to very rapid motion on the linear stage leading to damage on whatever is on top, or if anything is loose, flying objects.

The relationship between voltage and velocity is given (in the manual) as:

    velocity in counts/ms = (voltage/10) * GearCamScaleFactor

Note that the velocity of this is in `counts/ms`.
So to understand how the voltage will be converted into say `mm/s` we have to look at the `CountsPerUnit` 

The `GearCamScaleFactor` depends on other parameters set on the controller, such as:  

- `CountsPerUnit`
- `UnitsName`

The `CountPerUnit` parameter specifies the number of encoder counts per primary programming unit. 
We have not changed it from the factory settings but two different linear stages had two different values for this.

The `UnitsName` for us has always been `'mm'` and it's slightly unclear what values it can take from the Soloist documentation.

*Although 'Soloist user units' is used where possible to describe parameters, in all testing this has meant millimeters for position along the stage, and millimeters/second for speeds.
Therefore, if the Soloist user units is not mm or mm/s extra caution should be taken when using this*

Setup
-----

In order to use these scripts the .c/.cpp source code must be compiled. 
On Windows we have used gcc on Cygwin (https://cygwin.com/install.html) which needs to be installed (install Cygwin and during install select the `gcc-g++` package). 
The commands to build the exe's are contained in the `build.bat`, which can be run as is or each executable can be configured separately::

    $ g++ -o "..\exe\abort.exe" abort.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64

We may need to also include the `-I` flag to g++ with the location of the `.h` Soloist header files (e.g. add `-I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include"` as an argument to g++).

Position
--------

Position units are specified in millimeters on the stage. Our stage has been set up so that position 0 is at the front and position 1500 is at the back. The code should be able to adapt to different configurations of the stage by setting of the parameters.

Hard-coded Features
-------------------

In older versions of this code, there were a few hard coded lines in the Soloist source code, which need to be modified if this is to be moved to another system.

In the Aerobasic files `ramp_down_gain.ab`, `ramp_down_gain_nowait.ab`, `ramp_up_gain.ab` and `ramp_up_gain_nowait.ab`, the gear scale factor is hard coded at the top of the script::

    22    ramping_down = 1
    23    ramp_down_over_us = 200000
    24    gear_scale = -4000              <----- Needs to be set appropriately

Further, the location of the above `.ab` Aerobasic scripts are hard coded in the `listen_until.c`, `mismatch_ramp_down_at.cpp` and `mismatch_ramp_up_until.cpp` source files and need to be set if this is to be ported to another system.

Options
-------

Shared options for the Soloist source code are in ``src\rc_soloist.h``. They are:

`AI_CHANNEL` - integer channel ID of the analog input to the Soloist (our controller only has one option 0)

`AO_CHANNEL` - integer channel ID of the analog output from the Soloist (our controller only has one option 0)

`AO_SERVO_VALUE` - specifies the servo loop value that is tracked. See ANALOG TRACK in Aerobasic help and SoloistAdvancedAnalogTrack C Library function. 

Executables
-----------

The Soloist is controlled by a set of pre-compiled executable functions. This is not ideal, as each time an command is run we must connect and disconnect.