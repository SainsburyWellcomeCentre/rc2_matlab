classdef Coupled < handle
    
    properties
        ctl
        start_pos
        back_limit
        forward_limit
        direction
        vel_source
        run_once
    end
    
    
    methods
        
        function obj = Coupled(ctl)
            obj.ctl = ctl;
            obj.start_pos = ctl.config.stage.start_pos;
            obj.back_limit = ctl.config.stage.back_limit;
            obj.forward_limit = ctl.config.stage.forward_limit;
            obj.direction = 'forward_only';
            obj.vel_source = 'teensy';
            obj.run_once = true;
        end
        
        function run(obj)
            
            if obj.run_once
                obj.ctl.run(obj)
            end
            
            % start a process which will take 5 seconds
            proc = obj.ctl.soloist.block_test();
            % proc = obj.ctl.soloist.move_to(obj.start_pos, true);
            
            proc.wait_for(0.5);
            
            % wait a bit of time before starting the trial
            pause(5)
            
            % release block on the treadmill
            obj.ctl.treadmill.unblock()
            
            % start a process which will take 5 seconds
            proc = obj.ctl.soloist.block_test();
            % obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit)
            
            proc.wait_for(0.5);
            
            obj.ctl.processes.add_process(proc, 'block_test');
            obj.ctl.processes.wait_for('block_test');
            
            obj.ctl.treadmill.block()
            
            if obj.run_once
                % wait for reward to complete then stop acquisition
                obj.ctl.reward.start_reward(true)
                obj.ctl.stop_acq();
            else
                obj.ctl.reward.start_reward(false)
            end
        end
    end
end