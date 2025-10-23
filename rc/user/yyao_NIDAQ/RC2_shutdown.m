% Some simple lines for gracefully exiting the rollercoaster program

%% RC2_DoubleRotation_shutdown

try
    delete(ctl.gui.gui);
catch
end

try
    delete(ctl);
catch
end

close all;
clear config ctl;