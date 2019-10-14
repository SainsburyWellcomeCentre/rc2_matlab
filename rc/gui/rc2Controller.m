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
        
        
        function give_reward(obj)
            obj.setup.give_reward()
        end
        
        
        function block_treadmill(obj)
            obj.setup.block_treadmill()
        end
        
        
        function unblock_treadmill(obj)
            obj.setup.unblock_treadmill()
        end
        
        
        
        function move_to(obj)
            val = str2double(get(obj.view.handles.edit_move_to, 'string'));
            if ~isnumeric(val) || isinf(val) || isnan(val)
                error('value is not numeric')
            end
            obj.setup.move_to(val);
        end
    end
end