classdef WaveformDrivenRotation < handle
    properties
        handle_acquisition = true;
        wave_fname;
        waveform;
    end

    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
        target_axes;
        ctl % :class:`rc.main.RC2Controller` object controller.
    end

    methods
        function obj = WaveformDrivenRotation(ctl, config, fname)
            obj.ctl = ctl;
            obj.wave_fname = fname;
            obj.target_axes = config.ensemble.target_axes;
        end

        function load_wave(obj)
            if isempty(obj.wave_fname); return; end

            w = double(read_bin(obj.wave_fname, 1)); % file must be single channel

            obj.waveform = -10 + 20*(w(:, 1) + 2^15)/2^16; % TODO - offset transformation
        end

        function final_position = run(obj)
            final_position = 1;

            % load the waveform to be played
            obj.load_wave();

            if isempty(obj.waveform)
                final_position = 0;
                fprintf('NO WAVEFORM LOADED, SKIPPING\n')
                return
            end

            obj.running = true;

            % setup code to handle premature stopping
            h = onCleanup(@obj.cleanup);

            % startup initial communication
            obj.ctl.ensemble.communicate();

            % if this protocol is handling the acquisition, prepare for
            % acquisition
            if obj.handle_acquisition
                obj.ctl.prepare_acq();
            end

            % get and save the config for this protocol
            cfg = obj.get_config();
            obj.ctl.save_single_trial_config(cfg);

            % listen to correct source
            obj.ctl.multiplexer.listen_to('ni');

            % start PC listening to the correct trigger input
            obj.ctl.trigger_input.listen_to('soloist');

            % load the velocity waveform to NIDAQ
            obj.ctl.load_velocity_waveform(obj.waveform);

            if obj.handle_acquisition
                obj.ctl.start_acq();
            end

            % home the ensemble
            disp('>>> Homing');
            obj.ctl.ensemble.force_home(obj.target_axes);

            % Reset PSO
            disp('>>> Reset PSO');
            obj.ctl.ensemble.reset_pso(obj.target_axes);

            % Do 0 calibration - TODO

            % Ensemble offset - TODO

            % Set the ensemble to listen - TODO
            obj.ctl.ensemble.listen();

            % Start playing the waveform
            disp('>>> Start waveform');
            obj.ctl.play_velocity_waveform();

            % check to see AO is still running
            while obj.ctl.ni.ao.task.IsRunning
                disp('>>> AO task running');
                pause(0.005);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    return
                end
            end

            % stop acquisition if handling
            if obj.handle_acquisition
                obj.ctl.stop_acq();
            end

            disp('>>> Reset PSO');
            obj.ctl.ensemble.reset_pso(obj.target_axes);

            % the protocol is no longer running
            obj.running = false;
        end

        function stop(obj)
            obj.abort = true;
        end

        function cfg = get_config(obj)
            % TODO - other info
            cfg = {
                'prot.time_started', datestr(now, 'yyyymmdd_HH_MM_SS')
                };
        end

        function cleanup(obj)
            obj.running = false;
            obj.abort = false;

            if obj.handle_acquisition
                obj.ctl.ensemble.stop();
                obj.ctl.stop_acq();
            end
        end
    end
end

