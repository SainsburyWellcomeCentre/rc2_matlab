classdef rc2guiController < handle
    
    properties
        
        setup
        view
        
        move_to_pos
        reward_distance
        reward_location
        n_loops = 100
        back_distance = 50
        condition
        
        stage_limits
        speed_limits
    end
    
    
    
    methods
        
        function obj = rc2guiController(setup, config)
            
            obj.setup = setup;
            obj.stage_limits = config.stage.max_limits;
            obj.speed_limits = [10, 500];
            obj.move_to_pos = config.stage.start_pos;
            obj.reward_distance = 200; %TODO: config
            obj.condition = 'closed_loop'; %TODO: config
            obj.reward_location = 250; %TODO: config
            obj.view = rc2guiView(obj);
        end
        
        
        
        function delete(obj)    
            delete(obj.view);
        end
        
        
        
        function toggle_acquisition(obj)
            if obj.setup.acquiring
                obj.setup.stop_acq()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'PREVIEW');
            else
                obj.setup.prepare_acq()
                obj.setup.start_acq()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'STOP');
            end
        end
        
        
        
        function give_reward(obj)
            obj.setup.give_reward()
        end
        
        
        
        function changed_reward_duration(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'changed_reward_duration');
                set(obj.view.handles.edit_reward_duration, 'string', sprintf('%.1f', obj.setup.reward.duration))
                return
            end
            
            status = obj.setup.reward.set_duration(val);
            if status == -1
                set(obj.view.handles.edit_reward_duration, 'string', sprintf('%.1f', obj.setup.reward.duration))
                return
            end
        end
        
        
        
        function change_reward_location(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'change_reward_location');
                set(obj.view.handles.edit_reward_location, 'string', sprintf('%.1f', obj.reward_location))
                return
            end
            if val < 10 || val > 1400 % TODO: allow config
                fprintf('%s: %s ''val'' must be within reasonable bounds\n', class(obj), 'change_reward_location');
                set(obj.view.handles.edit_reward_location, 'string', sprintf('%.1f', obj.reward_location))
                return
            end 
        end
        
        
        
        function change_reward_distance(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'change_reward_distance');
                set(obj.view.handles.edit_reward_distance, 'string', sprintf('%.1f', obj.reward_distance))
                return
            end
            if val < 0 || val > 1400 % TODO: modify this
                fprintf('%s: %s ''val'' must be within reasonable bounds\n', class(obj), 'change_reward_distance');
                set(obj.view.handles.edit_reward_distance, 'string', sprintf('%.1f', obj.reward_distance))
                return
            end 
        end
        
        
        
        function closed_loop(obj, h_obj)
            val = get(h_obj, 'value');
            if val
                set(obj.view.handles.button_open_loop, 'value', false);
                obj.condition = 'closed_loop';
            else
                if strcmp(obj.condition, 'closed_loop')
                    set(obj.view.handles.button_closed_loop, 'value', true);
                end
            end
        end
        
        
        
        function open_loop(obj, h_obj)
            val = get(h_obj, 'value');
            if val
                set(obj.view.handles.button_closed_loop, 'value', false);
                obj.condition = 'open_loop';
            else
                if strcmp(obj.condition, 'open_loop')
                    set(obj.view.handles.button_open_loop, 'value', true);
                end
            end
        end
        
        
        
        function block_treadmill(obj)
            obj.setup.block_treadmill()
        end
        
        
        
        function unblock_treadmill(obj)
            obj.setup.unblock_treadmill()
        end
        
        
        
        function toggle_sound(obj)
            if ~obj.setup.sound.enabled
                return
            end
            if obj.setup.sound.state
                obj.setup.stop_sound()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'PLAY');
            else
                obj.setup.play_sound()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'STOP');
            end
        end
        
        
        
        function enable_sound(obj)
            obj.setup.sound.enable();
        end
        
        
        
        function disable_sound(obj)
            obj.setup.sound.disable();
        end
        
        
        
        function changed_move_to_pos(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'changed_move_to_pos');
                set(obj.view.handles.edit_move_to, 'string', sprintf('%.1f', obj.move_to_pos))
                return
            end
            
            if val > obj.stage_limits(1) || val < obj.stage_limits(2)
                fprintf('%s: %s ''val'' must be within stage limits\n', class(obj), 'changed_move_to_pos');
                set(obj.view.handles.edit_move_to, 'string', sprintf('%.1f', obj.move_to_pos))
                return
            end
        end
        
        
        
        function changed_speed(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                fprintf('%s: %s ''val'' must be numeric\n', class(obj), 'changed_speed');
                set(obj.view.handles.edit_speed, 'string', sprintf('%.1f', obj.move_to_pos))
                return
            end
            
            if val < obj.speed_limits(1) || val > obj.speed_limits(2)
                fprintf('%s: %s ''val'' must be within speed limits\n', class(obj), 'changed_speed');
                set(obj.view.handles.edit_speed, 'string', sprintf('%.1f', obj.setup.soloist.default_speed))
                return
            end
        end
        
        
        
        function move_to(obj)
            pos = str2double(get(obj.view.handles.edit_move_to, 'string'));
            if ~isnumeric(pos) || isinf(pos) || isnan(pos)
                error('position is not numeric')
            end
            speed = str2double(get(obj.view.handles.edit_speed, 'string'));
            if ~isnumeric(speed) || isinf(speed) || isnan(speed)
                error('speed is not numeric')
            end
            obj.setup.move_to(pos, speed);
        end
        
        
        
        function home_soloist(obj)
            obj.setup.home_soloist();
        end
        
        
        
        function reset_soloist(obj)
            obj.setup.soloist.reset();
        end
        
        
        
        function stop_soloist(obj)
            obj.setup.soloist.abort();
        end
        
        
        
        function set_save_to(obj)
            start_dir = obj.setup.saver.save_to;
            user_dir = uigetdir(start_dir, 'Choose save directory...');
            if ~user_dir; return; end
            
            obj.setup.set_save_save_to(user_dir);
            obj.view.save_to_updated();
        end
        
        
        
        function set_file_prefix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.set_save_prefix(str)
            obj.view.prefix_updated();
        end
        
        
        
        function set_file_suffix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.set_save_suffix(str)
            obj.view.suffix_updated();
        end
        
        
        
        function set_file_index(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            obj.setup.set_save_index(val);
            obj.view.index_updated();
        end
        
        
        
        function enable_save(obj, h_obj)
            val = get(h_obj, 'value');
            obj.setup.set_save_enable(val);
            obj.view.enable_updated();
        end
        
        
        
        function start_training(obj)
            
            % create a protocol sequence
            seq = setup_training_sequence(obj.setup, config, obj.reward_location, ...
                obj.reward_distance, obj.back_distance, obj.n_loops);
            seq.run()
        end
        
    end
end