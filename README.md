# Rollercoaster V2 (RC2) - DoubleRotation v1.0

This is a branch of Rollercoaster V2 repository that contains the software control code and documentation for the RC2DoubleRotation setup. The code controlling stage rotation cooperates with code controlling visual stimuli to drive the setup. 

## Hardware

The software was written to control the setup on the RC computer and the VisualStimuli computer. Both computers should be connected via Ethernet.

The code controls the following hardware on the RC computer:
1. An NI DAQ USB-6343
2. Two Aerotech rotatory stages (ADRT150-135 and ADRT260-160) with two Ensemble HLe controllers
3. A pump for reward

And the following hardware on the Visual Stimuli computer: 
4. A Basler acA640-750um camera


## Installation

This code has been developed on Windows 10 with MATLAB 2022b.
Folder 'visual_stimuli' should be installed on the Visual Stimuli computer. All other folders should be installed on the RC computer. 

In order to use all hardware the following should be installed on the RC computer:
1. Aerotech drivers for controlling the rotatory stages (Aerotech Ensemble v5.06.001, comes with controllers)
2. NI-DAQmx drivers

And the following should be installed on the Visual Stimuli computer: 
3. Psychtoolbox for Matlab
4. Basler drivers (Pylon Runtime v6.2.0.21487)
5. Python 3 with imageio, imageio-ffmpeg, pypylon packages

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

The RC2 codebase on the RC computer contains a user folder (rc/user) to place rig/experiment specific files in (see rc/user/template). Users should create their own named folder under user and place configurations, protocols and calibrations here. Config files should use relative paths from this directory wherever possible. Additionally config files should ensure the MATLAB search path for configs, protocols, calibrations is relative to the user folder, e.g.

```
% ensure searches are relative to user's path
rmpath(genpath(fileparts(config.user))); % Remove all user folders from the path
addpath(genpath(config.user)); % Add back only the current user folder
```

Similarly, on the Visual Stimuli computer there is a user folder 'visual_stimuli/user' to place experiment specific files. 

To run this DoubleRotation setup, start RC2 with files in user folder 'yyao_DoubleRotation' on both computers.

### Soloist Executables

Aerotech Soloist controllers are not used in this DoubleRotation setup. Howerver, the code retains .exe files from the main branch for communication with the Soloist are not tracked by the git repo as they are rig specific. If to use, these executables should be built from source for a fresh install of the software of if the source files are modified (use rc/soloist_c/src/build.bat)

## Documentation

See the README in the docs folder for instructions on how to build the documentation.
