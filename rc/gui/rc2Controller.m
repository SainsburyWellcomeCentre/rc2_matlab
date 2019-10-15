classdef rc2Controller < handle
    
    properties
        
        setup
        view
    end
    
    
    
    methods
        
        function obj = rc2Controller(setup)
            
            obj.setup = setup;
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
            
            obj.setup.saver.set_save_to(user_dir);
            set(obj.view.handles.edit_save_to, 'string', user_dir);
        end
        
        
        function set_file_prefix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.saver.set_prefix(str)
        end
        
        
        function set_file_suffix(obj, h_obj)
            str = get(h_obj, 'string');
            obj.setup.saver.set_suffix(str)
        end
        
        
        function set_file_index(obj, h_obj)
            val = str2double(get(h_obj, 'string'));
            obj.setup.saver.set_index(val);
            obj.view.index_updated();
        end
        
        
        function enable_save(obj, h_obj)
            val = get(h_obj, 'value');
            obj.setup.saver.set_enable(val);
            obj.view.enable_updated();
        end
    end
end