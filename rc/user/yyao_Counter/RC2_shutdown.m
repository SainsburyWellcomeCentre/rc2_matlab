% Some simple lines for gracefully exiting the rollercoaster program

%% RC2_DoubleRotation_shutdown

try
    gui.view.handles.delete;
catch
end

try
    delete(gui);
catch
end

try
    delete(ctl);
catch
end

close all;
clear config ctl gui;