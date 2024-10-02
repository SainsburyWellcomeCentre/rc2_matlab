classdef trial_LickTest < handle
    properties
        
        config
        ctl % :class:`rc.main.RC2Controller` object controller.

    end

    properties (SetAccess = private)

        running = false % Boolean specifying whether the trial is currently running.
        abort = false % Boolean specifying whether the trial is being aborted.
        
    end


    methods

        function obj = trial_LickTest(ctl, config)
            obj.config = config;
            obj.ctl = ctl;
        end


        function run(obj)

            

            obj.running = true;

            % setup code to handle premature stopping
            h = onCleanup(@obj.cleanup);

            obj.ctl.reward.reset_n_rewards_counter();   

            obj.ctl.prepare_acq();   
            obj.ctl.start_acq();     
            obj.running = true;


%             waveform = obj.sequence{i}.waveform;
%             obj.ctl.load_velocity_waveform(waveform);       % load the velocity waveform to NIDAQ

            obj.ctl.reward.reset_n_rewards_counter();

            % setup current trial lick detector
            obj.ctl.lick_detector.enable_reward = true;
            obj.ctl.lick_detector.start_trial();    % reset the lick detector

            % send lick_detector trigger to start lick detection
            pause(10)
            obj.ctl.waveform_peak_trigger();

            pause(30)

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

            obj.ctl.stop_acq();
        end

    end
end

