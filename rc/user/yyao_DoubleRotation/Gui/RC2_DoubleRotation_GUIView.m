classdef RC2_DoubleRotation_GUIView < handle
    
    properties
        controller
        gui
        handles
    end
    
    
    
    methods
        
        function obj = RC2_DoubleRotation_GUIView(controller)  
            
            obj.controller = controller;    
            obj.gui = RC2_DoubleRotation_GUI(obj.controller); % run RC2_DoubleRotation_GUI.mlapp
            obj.handles = obj.gui; 
            
            %%% UIFigure %%%
            obj.handles.UIFigure.Position = [410,230,707,526];
            obj.handles.versionLable_2.Text = obj.controller.setup.version;
            obj.handles.messageLable.Text = '';
            
            %%% stage %%%
%             obj.handles.PositionEditField.Value = sprintf('%.1f', obj.controller.move_to_pos);      
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
            addlistener(obj.controller.setup.saver, 'save_to', 'PostSet', @(src, evnt)obj.save_to_updated(src, evnt));          
            addlistener(obj.controller.setup.saver, 'prefix', 'PostSet', @(src, evnt)obj.prefix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'suffix', 'PostSet', @(src, evnt)obj.suffix_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'index', 'PostSet', @(src, evnt)obj.index_updated(src, evnt));
            addlistener(obj.controller.setup.saver, 'filename', 'PostSet', @(src, evnt)obj.filename_updated(src, evnt));
            addlistener(obj.controller.setup, 'acquiring_preview', 'PostSet', @(src, evnt)obj.acquiring_updated(src, evnt));   
            addlistener(obj.controller.setup.reward, 'duration', 'PostSet', @(src, evnt)obj.reward_duration_updated(src, evnt));
            addlistener(obj.controller.setup.sound, 'enabled', 'PostSet', @(src, evnt)obj.sound_enabled(src, evnt));           
            
 
        end
        

        
        %% Stage Panel 
        function ensemble_online(obj, ~, ~)                 % when Stages are moving disable the Stage Panel on GUI
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

        %% Experiment Panel 
        function script_updated(obj)                        
            obj.handles.LoadProtocolEditField.Value = obj.controller.current_script;
        end
        
        %% Saving Panel 
        function save_to_updated(obj, ~, ~)                 
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
        
        %% Pump Panel 
        function reward_duration_updated(obj, ~, ~)
            duration = obj.controller.setup.reward.duration;
            obj.handles.DurationEditField.Value = sprintf('%.1f',duration);
        end

        %% Sound Panel 
        function sound_enabled(obj, ~, ~)       
            % set the toggle buttons
            obj.handles.EnableSoundButton.Value = obj.controller.setup.sound.enabled;
            obj.handles.DisableSoundButton.Value = ~obj.controller.setup.sound.enabled;
            
            % of the sound has been disabled, make sure the button says
            % PLAY
            if ~obj.controller.setup.sound.enabled
                obj.handles.PlaySoundButton.Text = 'PLAY';
            end
        end
        
        %% AI Preview Panel 
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