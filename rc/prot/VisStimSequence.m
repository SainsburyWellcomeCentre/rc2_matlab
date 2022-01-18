classdef VisStimSequence < handle
% VisStimSequence Class for starting the visual stimulus from the GUI
%
%   VisStimSequence Properties:
%       running                 - whether the trial is currently running
%                                 (true = running, false = not running)
%       current_trial           - set to 1
%
%   VisStimSequence Methods:
%       run                     - run the trial
%       stop                    - stop the trial
%
%
%   The reason this class exists is to provide an interface like
%   ProtocolSequence (which the GUI uses to run training and experiments),
%   but for simply sending a trigger to the visual stimulus computer to
%   start a visual stimulus.
%
%   However, there are better ways of achiving this, e.g. maybe create a VisStim
%   trial class and then insert it into an object of ProtocolSequence
%   class.
%
%   TODO: there should be a get_config method
%
%   See also: VisStimSequence, run


    properties
        
        ctl
        running = false
    end
    
    properties (SetObservable = true)
        
        current_trial = 1
    end
    
    
    
    methods
        
        function obj = VisStimSequence(ctl)
        % VisStimSequence
        %
        %   VisStimSequence(CTL)
        %
        %   Protocol for running the visual stimulus.
        %       Start analog input (NIDAQ) recording and clock output.
        %       Sets digital output to visual stimulus low to start the presentation.  
        %
        %   In order to be consistent with the GUI call, had to include four
        %   features:
        %       1. run() method
        %       2. stop() method
        %       3. running property (bool) 
        %       4. current_trial property (int) (needs to be SetObservable)
        %   
        %   Does NOT control:       solenoid
        %                           soloist
        %                           sound
        %                           reward
        %
        %       So these must be setup as you want before you start.
        %
        %   Inputs:     ctl - main controller object with 'prepare_acq',
        %                       'start_acq', 'stop_acq' and 'vis_stim'
        %                       property which sets a digital output low
        %                       and high
        
            obj.ctl = ctl;
        end
        
        
        
        function run(obj)
        %%run Runs the "trial"
        %
        %   run() runs the "trial".
        %       1. Starts NIDAQ acquisition
        %       2. Sets digital output to vis stim computer high
        %       3. Waits for `stop`
        
            % function to run when function stops
            h = onCleanup(@obj.cleanup);
            
            % always running a single trial
            obj.current_trial = 1;
            
            % prepare and start acquisition
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
            obj.running = true;
            
            % wait a little bit of time before starting the stimulus
            % computer
            pause(2);
            
            % send trigger to visual stimulus computer
            obj.ctl.vis_stim.on();
            
            % wait for stop
            while obj.running
                pause(0.005);
            end
        end
        
        
        
        function stop(obj)
        %%stop Stops the "trial"
        %
        %   stop()
        %       1. Sets digital output to vis stim computer low
        %       2. Stops NIDAQ acquisition
        
            % set abort property true
            obj.running = false;
           
            % send trigger to visual stimulus computer
            obj.ctl.vis_stim.off();
            
            % stop acquisition
            obj.ctl.stop_acq();
        end
        
        
        
        function cleanup(obj)
        %%cleanup Stops the "trial"
        %
        %   cleanup() calls `stop`
        
            obj.stop();
        end
    end
end