classdef GUIview < handle

    properties
        ctrl
        gui
        handles
    end

    methods

        function obj = GUIview(ctrl)
            obj.ctrl = ctrl;
            obj.gui = GUI_main(obj.ctrl);
            obj.handles = obj.gui;

            % Experiment Panel
            obj.update_experiment_state();

            addlistener(obj.ctrl,'experiment_running','PostSet',@(src,evnt)obj.update_experiment_state(src,evnt));

            % Laser Panel
            obj.handles.pulsewidthsEditField.Value = num2str(obj.ctrl.laser.pulse_width);
            obj.handles.intervalsEditField.Value = num2str(obj.ctrl.laser.pulse_interval);
%             obj.handles.durationsEditField.Value = num2str(obj.ctrl.laser.pulse_duration);
            obj.update_laser_state();
            obj.update_laser_pulse_width();
%             obj.update_laser_pulse_duration();
            obj.update_laser_pulse_interval();
            addlistener(obj.ctrl.laser,'laser_state','PostSet',@(src,evnt)obj.update_laser_state(src,evnt));
            addlistener(obj.ctrl.laser,'pulse_width','PostSet',@(src,evnt)obj.update_laser_pulse_width(src,evnt));
%             addlistener(obj.ctrl.laser,'pulse_duration','PostSet',@(src,evnt)obj.update_laser_pulse_duration(src,evnt));
            addlistener(obj.ctrl.laser,'pulse_interval','PostSet',@(src,evnt)obj.update_laser_pulse_interval(src,evnt));
            addlistener(obj.handles,'RepeatedPulseButtonValue','PostSet',@(src,evnt)obj.update_gui_RepeatedPulseButton(src,evnt));
            addlistener(obj.ctrl.laser,'repeat_state','PostSet',@(src,evnt)obj.update_gui_RepeatedPulseButton(src,evnt));
            
        end
        

        % Experiment Panel
        function update_experiment_state(obj,~,~)
            if obj.ctrl.experiment_running
                obj.handles.stateLamp.Color = [0,1,0];          % green -- on
            else
                obj.handles.stateLamp.Color = [0.9,0.9,0.9];    % white -- off
            end
        end

        % Laser Panel
        function update_laser_state(obj,~,~)
            if obj.ctrl.laser.laser_state
                obj.handles.laserstateLamp.Color = [0,1,0];
            else
                obj.handles.laserstateLamp.Color = [0.9,0.9,0.9];
            end
        end

        function update_laser_pulse_width(obj,~,~)
            obj.handles.pulsewidthsEditField.Value = num2str(obj.ctrl.laser.pulse_width);
        end

        function update_laser_pulse_duration(obj,~,~)
            obj.handles.durationsEditField.Value = num2str(obj.ctrl.laser.pulse_duration);
        end

        function update_laser_pulse_interval(obj,~,~)
            obj.handles.intervalsEditField.Value = num2str(obj.ctrl.laser.pulse_interval);
        end

        function update_gui_RepeatedPulseButton(obj,~,~)
            if obj.handles.RepeatedPulseButtonValue == 1
                obj.handles.laserstateLamp.Color = [0,1,0];
                obj.handles.RepeatedPulseButton.Text = 'Abort';
            else
                obj.handles.laserstateLamp.Color = [0.9,0.9,0.9];
                obj.handles.RepeatedPulseButton.Text = 'Repeated Pulse';
            end
            if obj.ctrl.laser.repeat_state ~=1
                obj.handles.laserstateLamp.Color = [0.9,0.9,0.9];
                obj.handles.RepeatedPulseButton.Text = 'Repeated Pulse';
            end
        end

        % Stage Panel
        function update_stage_timer(obj,~,~)
            if ~isnan(obj.gui.stage_start)
                time.t = obj.gui.session_duration - obj.gui.stage_start;
                time.h = floor(time.t/3600); 
                time.m = floor((time.t-3600*time.h)/60);
                time.m_str = num2str(time.m);   
                if time.m<10
                    time.m_str = strcat('0',time.m_str);
                end
                time.s = time.t-3600*time.h-60*time.m;
                time.s_str = sprintf('%.2f',time.s);
                if time.s<10
                    time.s_str = strcat('0',time.s_str);
                end
                obj.handles.StageTimerLabel.Text = strcat(num2str(time.h),':',time.m_str,':',time.s_str);
            else
                obj.handles.StageTimerLabel.Text = 'null';
            end
        end


    end
end