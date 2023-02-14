clear all; %close all; 
clc;

%% set up controller
config = config_yyao();
% config.connection.remote_ip = '172.24.242.177';
% config.connection.remote_port_prepare = 43056;
% config.connection.remote_port_stimulus = 43057;
% if isempty(config), return, end

ctl = RC2_DoubleRotation_Controller2(config);
% ni = NI(config);   % 检查NIDAQ状态，创建 模拟输入输出，数字输入输出，和计数器输出 数据采集
% ensemble = Ensemble(config);   % 控制平台的旋转

% trial
wform = 'C:\Users\Margrie_Lab1\Documents\MATLAB\rc2_matlab\rc\user\mvelez(not in use)\waveforms\CA_529_2_trn11_001_single_trial_001.bin';
% trialTest = WaveformOnly(ctl, config, wform);
trialTest = WaveformDrivenRotation2(ctl, config, wform);
trialTest.run();