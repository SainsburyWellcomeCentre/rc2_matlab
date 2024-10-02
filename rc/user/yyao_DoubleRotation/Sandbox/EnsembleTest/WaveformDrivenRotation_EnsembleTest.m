classdef WaveformDrivenRotation_EnsembleTest < handle
    properties
        handle_acquisition = true;
        wave_fname;
        waveform;
        ctl % :class:`rc.main.RC2Controller` object controller.
        target_axes;
        real_time_offset_error
        SpeedFeedback
        PositionFeedback
        ensembleHandle
    end

    properties (SetAccess = private)
        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
        all_axes;
        
        
    end


    methods

        function obj = WaveformDrivenRotation_EnsembleTest(ctl, config, wform)
            obj.ctl = ctl;
            obj.waveform = wform;
            obj.all_axes = config.ensemble.all_axes;
            obj.target_axes = config.ensemble.target_axes;
        end


        function load_wave(obj)
            if isempty(obj.wave_fname); return; end

            w(:,1) = double(read_bin(obj.wave_fname, 1)); % file must be single channel
            w(:,2) = w(:,1);

            obj.waveform = -10 + 20*(w + 2^15)/2^16; % TODO - offset transformation
%             obj.waveform(:,isnan(obj.target_axes))=0;
%             obj.waveform(:,1)=0; obj.waveform(:,2)=0;
            obj.waveform(:,1)=-0;
            obj.waveform(:,2)=-obj.waveform(:,1);
        end


        function final_position = run(obj)
            final_position = 1;

            % load the waveform to be played
%             obj.load_wave();

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

            % load the velocity waveform to NIDAQ
            obj.ctl.load_velocity_waveform(obj.waveform);

            if obj.handle_acquisition
                obj.ctl.start_acq();
            end

            obj.ctl.ensemble.set_targetaxes([0 NaN]);
            obj.ctl.ensemble.move_to(30, 40, true);
            obj.ctl.ensemble.set_targetaxes([NaN 1]);
            obj.ctl.ensemble.move_to(30, 40, true);
% %{
            % home the ensemble
            disp('>>> Homing');
            obj.ctl.ensemble.set_targetaxes(obj.all_axes);
            obj.ctl.ensemble.home(true);
            % Reset PSO
            disp('>>> Reset PSO');
            obj.ctl.ensemble.set_targetaxes(obj.all_axes);
            obj.ctl.ensemble.reset_pso();

            % Do 0 calibration - TODO
%             obj.ctl.ensemble.set_targetaxes(obj.target_axes);
%             obj.real_time_offset_error = obj.ctl.ensemble.calibrate_zero();
%             disp('real_time_offset_error');
%             obj.real_time_offset_error
% %{
            % Ensemble offset - TODO
%             obj.ctl.ensemble.ai_offset = -real_time_offset_error;



            % Set the ensemble to listen
            disp('>>> Setup Ensemble listen');
%             ensembleHandle = obj.ctl.ensemble.listen(obj.target_axes);
            obj.ctl.ensemble.set_targetaxes(obj.target_axes);
            obj.ensembleHandle = obj.ctl.ensemble.listen();

            % Start playing the waveform on the NIDAQ
            disp('>>> Start waveform');
            obj.ctl.play_velocity_waveform();

            % check to see AO is still running
            disp('>>> AO task running');
            i = 1;
            while obj.ctl.ni.ao.task.IsRunning
                obj.SpeedFeedback(i,1) = EnsembleStatusGetItem  (obj.ensembleHandle, obj.all_axes(1), EnsembleStatusItem.VelocityFeedback);
                obj.PositionFeedback(i,1) = EnsembleStatusGetItem  (obj.ensembleHandle, obj.all_axes(1), EnsembleStatusItem.PositionFeedback);
                obj.SpeedFeedback(i,2) = EnsembleStatusGetItem  (obj.ensembleHandle, obj.all_axes(2), EnsembleStatusItem.VelocityFeedback);
                obj.PositionFeedback(i,2) = EnsembleStatusGetItem  (obj.ensembleHandle, obj.all_axes(2), EnsembleStatusItem.PositionFeedback);
                i=i+1;
                pause(0.005);
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    return
                end
            end
            disp('>>> AO task finished');

            
            % Stop Ensemble listen
            disp('>>> Stop Ensemble listen');
            obj.ctl.ensemble.stop_listen(obj.ensembleHandle,true);
            
            obj.ctl.ensemble.set_targetaxes(obj.all_axes);
            obj.ctl.ensemble.home(true);

            % stop acquisition if handling
            if obj.handle_acquisition
                obj.ctl.stop_acq();
            end

            obj.ctl.ensemble.abort_all();
%}
            disp('>>> Reset PSO');
            obj.ctl.ensemble.set_targetaxes(obj.all_axes);
            obj.ctl.ensemble.reset_pso();

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

