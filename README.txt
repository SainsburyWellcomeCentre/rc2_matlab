

Configuration files
-------------------

The main configuration file is in %TOP_DIR%\rc\main\configs\config_default.m, where TOP_DIR is the location on the system of the rc2_matlab directory. This file should contain most of the configuration variables for a day to day basis.

Other configuration variables are contained in:

%TOP_DIR%\soloist_c\src\rc_soloist.h
%TOP_DIR%\teensy_ino\libraries\options\options.h

These files contain variables that are less often modified, but changing them requires extra steps to implement. If a variable in the rc_soloist.h file is changed, then some or all of the executables will need to be rebuilt and placed in %TOP_DIR%\soloist_c\exe\.  If a variable in the Teensy options.h file is changed, then the options.h will have to be copied to the Arduino libraries directory.
