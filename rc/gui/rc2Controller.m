classdef rc2Controller < handle
    
    properties
        
        setup
        view
        
        move_to_pos
        stage_limits
    end
    
    
    
    methods
        
        function obj = rc2Controller(setup)
            
            obj.setup = setup;
            obj.stage_limits = setup.config.stage.max_limits;
            obj.move_to_pos = setup.config.stage.start_pos;
            obj.view = rc2View(obj);
        end
        
        
        function delete(obj)
            
            delete(obj.view);
        end
        
        
        function toggle_acquisition(obj)
            if obj.setup.acquiring
                obj.setup.stop_acq()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'ACQUIRE');
            else
                obj.setup.prepare_acq()
                obj.setup.start_acq()
                set(obj.view.handles.pushbutton_toggle_acq, 'string', 'STOP');
            end
        end
        
        
        function give_reward(obj)
            obj.setup.give_reward()
        end
        
        
        function block_treadmill(obj)
            obj.setup.block_treadmill()
        end
        
        
        function unblock_treadmill(obj)
            obj.setup.unblock_treadmill()
        end
        
        
        function toggle_sound(obj)
            if obj.setup.sound.state
                obj.setup.sound.stop()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'PLAY');
            else
                obj.setup.sound.start()
                set(obj.view.handles.pushbutton_toggle_sound, 'string', 'STOP');
            end
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
        
        
        
        function move_to(obj)
            val = str2double(get(obj.view.handles.edit_move_to, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                error('value is not numeric')
            end
            obj.setup.move_to(val);
        end
        
        
        function reset(obj)
            obj.setup.soloist.reset();
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
    end
end