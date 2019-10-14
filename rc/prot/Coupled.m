classdef Coupled < handle
    
    properties
        ctl
        start_pos
        back_limit
        forward_limit
        direction
    end
    
    
    methods
        
        function obj = Coupled(ctl)
            obj.ctl = ctl;
            obj.start_pos = ctl.config.stage.start_pos;
            obj.back_limit = ctl.config.stage.back_limit;
            obj.forward_limit = ctl.config.stage.forward_limit;
            obj.direction = 'forward_only';
        end
        
        function run(obj)
            
            obj.ctl.run(obj)
            obj.ctl.soloist.move_to(obj.start_pos, true)
            pause(5)
            obj.ctl.treadmill.unblock()
            obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit)
            pause(5)
            obj.ctl.treadmill.block()
            obj.ctl.reward.start_reward()
        end
    end
end