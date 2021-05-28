function example_vis_stim_function(tp_main)

% setup psychtoolbox etc.
tic;
while toc < 2
    fprintf('doingstuff\n');
end


% stimulus order
s_plus = [true, false, true, false, false, true];

% tell other computer setup is finished
tp_main.setup_complete();


% pretend we are looping over trials
for i = 1 : length(s_plus)
    
    % tell RC2 which stimulus type (s+ or s-)
    tp_main.notify_of_stimulus_type(s_plus(i));
    
    % wait for reply
    fprintf('waiting for reply from RC2\n');
    reply = tp_main.wait_for_rc2();
    
    % if other computer has stopped break and cleanup
    if strcmp(reply, 'rc2_stopping')
        fprintf('stopping visual stimulus: %i\n', i);
        break
    end
    
    tic;
    while toc < 2
        fprintf('doingstuff\n');
    end
end
