# Rollercoaster V2 (RC2) - DoubleRotation v1.0

This repository contains the software control code and documentation for the Rollercoaster V2 setup.

## Hardware

The software was written to control the following hardware:

1. An NI USB-6229 DAQ
2. A Teensy 3.2
3. An Aerotech linear stage (ACT115) with Soloist HLe controller 
4. A multiplexer
5. A pump for reward
6. A solenoid for blocking the treadmill

## Installation

This code has been developed on Windows 7 with MATLAB 2018b.

In order to use all hardware the following should be installed on the system:

1. Aerotech drivers for controlling the linear stage (software comes with stage)
2. Arduino software for controlling the Teensy's (https://www.pjrc.com/teensy/td_download.html)
3. NI-DAQmx drivers

## Usage best practices

Different physical RC2 rigs will implement different hardware interactions and configurations. Therefore, some parts of the code base will not be transferable across rigs and should be configured locally for a particular setup. In particular, configuration descriptions and Soloist communication executables will vary between rigs, and should therefore be tailored for each rig. 

### Git configuration

Individual users of RC2 should create their own branch or fork of the repo (rig-user) and implement any rig specific changes there.

For example, to install RC2 on a new rig for a new user:
1. Clone the main repo.
2. Create a new branch named <rig-user> (e.g. 3p-aerskine).
3. This branch should be used *only* for adding user and rig specific configs, protocols, calibrations in the rc/user folder.
    - Use the configs in the rc\user\template folder as a guide as these include relative pathing. 
    - Configs can also be copied from other users (although ensure that they use relative paths as well). Make sure that copied configs are renamed to reflect the new user / rig.
4. If any changes to the main RC2 codebase are required (e.g. new Sensor module, GUI changes) they should be made in the main branch (or a development branch of the main branch that is then merged back into main).
5. To implement those changes, users should rebase their rig-user branch onto the main branch.

### Configuration, Calibration and Protocols

The RC2 codebase contains a user folder (rc/user) to place rig/experiment specific files in (see rc/user/template). Users should create their own named folder under user and place configurations, protocols and calibrations here. Config files should use relative paths from this directory wherever possible. Additionally config files should ensure the MATLAB search path for configs, protocols, calibrations is relative to the user folder, e.g.

```
% ensure searches are relative to user's path
rmpath(genpath(fileparts(config.user))); % Remove all user folders from the path
addpath(genpath(config.user)); % Add back only the current user folder
```

### Soloist Executables

The .exe files for communication with the Soloist are not tracked by the git repo as they are rig specific. These executables should be built from source for a fresh install of the software of if the source files are modified (use rc/soloist_c/src/build.bat)

## Documentation

See the README in the docs folder for instructions on how to build the documentation.
