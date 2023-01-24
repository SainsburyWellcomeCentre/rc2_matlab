classdef RotationTest < handle
    properties
        position; % relative position to move to
        handle_acquisition = true % Boolean specifying whether we are running this as a single trial (true) or as part of a :class:`rc.prot.ProtocolSequence` (false).
    end

    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
        ctl % :class:`rc.main.RC2Controller` object controller.
    end
    
    properties (Hidden = true)
        
    end

    methods
        function obj = RotationTest(ctl, config, position)           
            % Constructor for a :class:`rc.prot.StageOnly` protocol.
            %
            % :param ctl: :class:`rc.main.RC2Controller` object for interfacing with the stage.
            % :param config: The main configuration file.
            % :param fname: Full path to the .bin file from which to read the waveform data to output on the analog outputs. 
        
            VariableDefault('fname', []);
            
            obj.ctl = ctl;
            obj.position = position;
        end

        function final_position = run(obj)
            % Assume we have completed without error
            final_position = 1;

            obj.running = true;

            % setup code to handle premature stopping
            h = onCleanup(@obj.cleanup);

            % do initial communication
            obj.ctl.ensemble.communicate();

            if obj.handle_acquisition
                obj.ctl.prepare_acq();
            end

            % switch vis stim off
            obj.ctl.vis_stim.off();

%                 % TODO get and save config
%                 cfg = obj.get_config();
%                 obj.ctl.save_single_trial_config(cfg);

            % listen to correct source
            obj.ctl.multiplexer_listen_to('ni');

            % start PC listening to correct trigger input
            % N.B. The config file lists the trigger channel as
            % 'soloist' but this is really just a digital line. Here
            % we are in fact listening to ensemble but it's just a line
            % mapping so left named as soloist for now.
            obj.ctl.trigger_input.listen_to('soloist');

            % play sound and start acquisition
            if (obj.handle_acquisition)
                obj.ctl.play_sound();
                obj.ctl.start_acq();
            end

            % move operation (TODO hard coded val)
            obj.ctl.ensemble.move_to([0, 1], [150 -150], [obj.ctl.ensemble.default_speed, obj.ctl.ensemble.default_speed], false);

            % if handling the acquisition stop 
            if obj.handle_acquisition
                obj.ctl.stop_acq();
                obj.ctl.stop_sound();
            end
        end

        function cleanup(obj)
            obj.running = false;
            obj.abort = false;

            % TODO other stopping stuff
        end
    end
end

