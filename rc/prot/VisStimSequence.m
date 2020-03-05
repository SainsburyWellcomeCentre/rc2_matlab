classdef VisStimSequence < handle
    
    properties
        ctl
        running = false
    end
    
    properties (SetObservable = true)
        current_trial = 1
    end
    
    methods
        
        function obj = VisStimSequence(ctl)
        %%obj = VISSTIMSEQUENCE(ctl)
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
           
            % set abort property true
            obj.running = false;
           
            % send trigger to visual stimulus computer
            obj.ctl.vis_stim.off();
            
            % stop acquisition
            obj.ctl.stop_acq();
        end
        
        
        function cleanup(obj)
            obj.stop();
        end
    end
end