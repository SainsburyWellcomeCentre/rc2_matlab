% Main startup script to interface with the rollercoaster setup
%
% leaves 3 variables in the MATLAB workspace
%       config - general configuration parameters *at startup* (changing
%           these after startup will have no effect, unless you rerun
%           RC2Controller(config) etc.
%       ctl - main object for interfacing with the setup, contains several
%           objects for interaction with each component of the setup as
%           well as display
%       gui - main object for interfacing with the gui. unlikely there will
%           be much use for using it other than debugging

%% RC2_startup
% requirements
root_path = 'C:\Users\Margrie_Lab1\Documents\repos\swc\';
addpath(genpath(fullfile(root_path,'rc2_matlab\rc\classes')));
addpath(genpath(fullfile(root_path,'rc2_matlab\rc\nidaq')));
addpath(genpath(fullfile(root_path,'rc2_matlab\rc\util')));
% addpath(genpath(fullfile(root_path,'rc2_matlab\rc\user\yyao_DoubleRotation')));
clear root_path;

% add user folder
[path,~] = fileparts(mfilename("fullpath"));
addpath(genpath(path));
clear path;

% setup configuration
config = config_Counter();
if isempty(config), return, end


% main controller object
ctl = Controller(config);    


%{

Use MATLAB 2021a or newer version


1. To start-up, run
	>> RC2_startup();

2. To run experiment, run
   	>> ctl.start_experiment();

3. To end experiment,
	>> ctl.stop_experiment();

4. To exit, 
   on NIDAQ PC, run 
	>> RC2_shutdown();

%}