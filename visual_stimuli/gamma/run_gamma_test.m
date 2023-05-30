function run_gamma_test()
%% RUN_GAMMA_TEST()
%   presents 6 (evenly spaced) grey level values to the screen.
%   to switch between the grey screens press enter (there is a 2s timeout
%   after each grey screen update, so wait at least 2s before pressing
%   enter)
%   you can exit any time by pressing "esc"


levels = 0:0.2:1;

% Specify stimulus type to get the correct options.
screen_name         = 'sony_projector';
screen_number       = 2;
calibration_on      = true;
calibration_file    = 'gamma\gamma_correction_sony_projector.mat';


ptb                         = PsychoToolbox();
ptb.calibration_on          = calibration_on;

% Load the gamma calibration file.
if ptb.calibration_on
    load(calibration_file, 'gamma_table');
    ptb.gamma_table         = gamma_table;
end

% Information about the setup.
setup                       = SetupInfo(ptb, screen_name);
setup.set_screen_number(screen_number);

% Create an object controlling the background
bck                         = Background(ptb);

try
    
    % Startup psychtoolbox
    ptb.start(setup.screen_number);
    
    
    for i = 1 : length(levels)
        
        is_waiting = 1;
        
        bck.colour = levels(i);
        bck.buffer();
        ptb.flip();
        
        pause(2)
        
        % Check for key-press from the user.
      	while is_waiting
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape')), error('escape'), end
            if keyCode(KbName('return')), is_waiting = 0; end
        end
    end
    
    ptb.stop();
    
catch ME
    
    
    ptb.stop();
    
    rethrow(ME);
end






