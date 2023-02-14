classdef RC2_DoubleRotation_GUIView < handle
    
    properties
        controller
        gui
        handles
    end
    
    
    
    methods
        
        function obj = RC2_DoubleRotation_GUIView(controller)  % 输入变量为RC2_DoubleRotation_GUIController类变量
            
            obj.controller = controller;    % RC2_DoubleRotation_GUIController类变量
            obj.gui = RC2_DoubleRotation_GUI(obj.controller); % 启动GUI界面RC2_DoubleRotation_GUI.mlapp
            obj.handles = obj.gui;  % 将GUI界面赋值给obj.handles变量以便操作。
            
            %%% UIFigure %%%
            obj.handles.UIFigure.Position = [410,230,707,526];
            obj.handles.versionLable_2.Text = obj.controller.setup.version;
            obj.handles.messageLable.Text = '';
            
            %%% stage %%%
%             obj.handles.PositionEditField.Value = sprintf('%.1f', obj.controller.move_to_pos);      % 将GUIcontroller中设定的move_to_pos值传递给GUI变量edit_move_to
%             obj.handles.SpeedEditField.Value = sprintf('%.1f', obj.controller.setup.soloist.default_speed);
            %%% experiment %%%
            obj.handles.LoadProtocolEditField.Value = '';
            %%% save %%%
            save_to = obj.controller.setup.saver.save_to;
            obj.handles.SavePathEditField.Value = save_to;
            AnimalID = obj.controller.setup.saver.prefix;
            obj.handles.AnimalIDEditField.Value = AnimalID;
            SessionNum = obj.controller.setup.saver.suffix;
            obj.handles.SessionEditField.Value = SessionNum;
            Filename = obj.controller.setup.saver.filename;
            obj.handles.DataFilename_val.Text = Filename;
            Protocol = obj.controller.setup.saver.index;
            if isempty(Protocol)
                obj.handles.StartExperimentButton.Enable = false;
            else
                obj.handles.StartExperimentButton.Enable = true;
            end
            %%% reward %%%
            obj.handles.DurationEditField.Value = sprintf('%.1f',obj.controller.setup.reward.duration);
            %%% sound %%%
            obj.handles.EnableSoundButton.Value = obj.controller.setup.sound.enabled;
            obj.handles.DisableSoundButton.Value = ~obj.controller.setup.sound.enabled;
            if obj.controller.setup.sound.enabled
                obj.handles.PlaySoundButton.Enable = 'on';
            else
                obj.handles.PlaySoundButton.Enable = 'off';
            end
            
            addlistener(obj.controller.setup.ensemble, 'online', 'PostSet', @(src, evnt)obj.ensemble_online(src, evnt));
            addlistener(obj.controller.setup.saver, 'save_to', 'PostSet', @(src, evnt)obj.save_to_updated(src, evnt));          % 侦听obj.gui.view.controller.setup.saver对象的'save_to'事件，一旦侦听到则回调save_to_updated函数。
            addlistener(obj.controller.setup.saver, 'prefix', 'PostSet', @(src, evnt)obj.prefix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'suffix', 'PostSet', @(src, evnt)obj.suffix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'index', 'PostSet', @(src, evnt)obj.index_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'filename', 'PostSet', @(src, evnt)obj.filename_updated(src, evnt));
            addlistener(obj.controller.setup, 'acquiring_preview', 'PostSet', @(src, evnt)obj.acquiring_updated(src, evnt));    % 侦听obj.gui.view.controller.setup对象的'acquiring_preview'事件，一旦侦听到则回调acquiring_updated函数。
            addlistener(obj.controller.setup.reward, 'duration', 'PostSet', @(src, evnt)obj.reward_duration_updated(src, evnt));
            addlistener(obj.controller.setup.sound, 'enabled', 'PostSet', @(src, evnt)obj.sound_enabled(src, evnt));            % 侦听obj.gui.view.controller.setup.sound对象的'enabled'事件，一旦侦听到则回调sound_enabled函数。
            
%             obj.hide_ui();  % 最初将所有组件设置为不可用，Home过之后才可用
        end
        
        %{
        function hide_ui(obj)
            
            set(obj.handles.edit_move_to, 'enable', 'off');
            set(obj.handles.edit_speed, 'enable', 'off');
            set(obj.handles.pushbutton_move_to, 'enable', 'off');
            set(obj.handles.pushbutton_reset, 'enable', 'off');
            set(obj.handles.edit_reward_location, 'enable', 'off');
            set(obj.handles.edit_reward_distance, 'enable', 'off');
            set(obj.handles.pushbutton_start_training, 'enable', 'off');
            set(obj.handles.button_closed_loop, 'enable', 'off');
            set(obj.handles.button_open_loop, 'enable', 'off');
            set(obj.handles.pushbutton_script, 'enable', 'off');
            set(obj.handles.pushbutton_start_experiment, 'enable', 'off');
            set(obj.handles.pushbutton_change_save_to, 'enable', 'off');
            set(obj.handles.edit_file_prefix, 'enable', 'off');
            set(obj.handles.edit_file_suffix, 'enable', 'off');
            set(obj.handles.edit_file_index, 'enable', 'off');
            set(obj.handles.checkbox_enable_save, 'enable', 'off');
        end
        
        
        function show_ui_after_home(obj)
            
            set(obj.handles.edit_move_to, 'enable', 'on');
            set(obj.handles.edit_speed, 'enable', 'on');
            set(obj.handles.pushbutton_move_to, 'enable', 'on');
            set(obj.handles.pushbutton_reset, 'enable', 'on');
            set(obj.handles.edit_reward_location, 'enable', 'on');
            set(obj.handles.edit_reward_distance, 'enable', 'on');
            set(obj.handles.pushbutton_start_training, 'enable', 'on');
            set(obj.handles.button_closed_loop, 'enable', 'on');
            set(obj.handles.button_open_loop, 'enable', 'on');
            set(obj.handles.pushbutton_script, 'enable', 'on');
            set(obj.handles.pushbutton_start_experiment, 'enable', 'on');
            set(obj.handles.pushbutton_change_save_to, 'enable', 'on');
            set(obj.handles.edit_file_prefix, 'enable', 'on');
            set(obj.handles.edit_file_suffix, 'enable', 'on');
            set(obj.handles.edit_file_index, 'enable', 'on');
            set(obj.handles.checkbox_enable_save, 'enable', 'on');
        end
        %}
        
        %% Stage面板
        function ensemble_online(obj, ~, ~)                 % Stage移动（或禁止移动）过程中禁用GUI界面相应axis的移动按钮（函数有效，但GUI并不能在stage移动过程中及时更新）
            obj.handles.HOMEButton.Enable   = 'on';
%             obj.handles.ResetButton.Enable  = 'on';
            obj.handles.StopButton.Enable   = 'on';
            obj.handles.MoveToButton.Enable = 'on';
            obj.handles.HOMEButton_2.Enable   = 'on';
%             obj.handles.ResetButton_2.Enable  = 'on';
            obj.handles.StopButton_2.Enable   = 'on';
            obj.handles.MoveToButton_2.Enable = 'on';
            if obj.controller.setup.ensemble.online(1)
                    obj.handles.HOMEButton.Enable   = 'off';
                    obj.handles.ResetButton.Enable  = 'off';
                    obj.handles.StopButton.Enable   = 'off';
                    obj.handles.MoveToButton.Enable = 'off';
            end
            if obj.controller.setup.ensemble.online(2)
                obj.handles.HOMEButton_2.Enable   = 'off';
                obj.handles.ResetButton_2.Enable  = 'off';
                obj.handles.StopButton_2.Enable   = 'off';
                obj.handles.MoveToButton_2.Enable = 'off';
            end
        end

        %% Experiment面板
        function script_updated(obj)                        % 更新RC2 GUI界面Load protocol file...路径显示
            obj.handles.LoadProtocolEditField.Value = obj.controller.current_script;
        end
        
        %% Saving面板
        function save_to_updated(obj, ~, ~)                 % 更新RC2 GUI界面save to路径显示
            str = obj.controller.setup.saver.save_to;
            obj.handles.SavePathEditField.Value = str;
        end
        
        function prefix_updated(obj, ~, ~)
            str = obj.controller.setup.saver.prefix;
            obj.handles.AnimalIDEditField.Value = str;
            filename = sprintf('%s_%s_%s', obj.controller.setup.saver.prefix, obj.controller.setup.saver.suffix, obj.controller.setup.saver.index); 
            obj.controller.setup.saver.set_filename(filename);
        end
        
        function suffix_updated(obj, ~, ~)
            str = obj.controller.setup.saver.suffix;
            obj.handles.SessionEditField.Value = str;
            filename = sprintf('%s_%s_%s', obj.controller.setup.saver.prefix, obj.controller.setup.saver.suffix, obj.controller.setup.saver.index); 
            obj.controller.setup.saver.set_filename(filename);
        end
        
        function index_updated(obj, ~, ~)
            str = obj.controller.setup.saver.index;
            if isempty(str)
                obj.handles.StartExperimentButton.Enable = false;
            else
                obj.handles.StartExperimentButton.Enable = true;
            end
            filename = sprintf('%s_%s_%s', obj.controller.setup.saver.prefix, obj.controller.setup.saver.suffix, obj.controller.setup.saver.index); 
            obj.controller.setup.saver.set_filename(filename);
        end
        
        function filename_updated(obj, ~, ~)
            str = obj.controller.setup.saver.filename;
            obj.handles.DataFilename_val.Text = str;
        end
        
        %% Pump面板
        function reward_duration_updated(obj, ~, ~)
            duration = obj.controller.setup.reward.duration;
            obj.handles.DurationEditField.Value = sprintf('%.1f',duration);
        end

        %% Sound面板
        function sound_enabled(obj, ~, ~)       % 根据Sound类enable属性值更新GUI界面单选框显示
            % set the toggle buttons
            obj.handles.EnableSoundButton.Value = obj.controller.setup.sound.enabled;
            obj.handles.DisableSoundButton.Value = ~obj.controller.setup.sound.enabled;
            
            % of the sound has been disabled, make sure the button says
            % PLAY
            if ~obj.controller.setup.sound.enabled
                obj.handles.PlaySoundButton.Text = 'PLAY';
            end
        end
        
        %% AI Preview面板
        function acquiring_updated(obj, ~, ~)
            if obj.controller.setup.acquiring_preview
                obj.handles.PreviewButton.Text = 'STOP';
            else
                obj.handles.PreviewButton.Text = 'PREVIEW';
            end
        end
        
        function delete(obj)
%             delete(obj.handles.output);
        end   
    end
end