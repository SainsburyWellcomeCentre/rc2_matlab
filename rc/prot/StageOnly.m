classdef StageOnly < handle
    
    properties
        ctl
        start_pos
        vel_source
        back_limit
        forward_limit
        direction
        run_once
        wave_fname
        waveform
    end
    
    
    methods
        
        function obj = StageOnly(ctl, fname)
            obj.ctl = ctl;
            obj.start_pos = ctl.config.stage.start_pos;
            obj.vel_source = 'ni';
            obj.direction = 'forward_only';
            obj.run_once = true;
            obj.wave_fname = fname;
            
            obj.load_wave();
        end
        
        
        function load_wave(obj)
            w = double(read_bin(obj.wave_fname, 1));
            obj.waveform = -10 + 20*(w + 2^15)/2^16;  %TODO:  config... but StageOnly shouldn't have to worry about it.
        end
        
        
        function run(obj)
            
            if isempty(obj.waveform)
                fprintf('NO WAVEFORM LOADED, SKIPPING\n')
                return
            end
            
            % load the velocity waveform
            obj.ctl.load_velocity_waveform(obj.waveform);
            
            if obj.run_once    
                obj.ctl.run(obj)
            end
            
            % start a process which will take 5 seconds
            proc = obj.ctl.soloist.block_test();
            % proc = obj.ctl.soloist.move_to(obj.start_pos, true);
            
            proc.wait_for(0.5);
            
            pause(5)
            
            obj.ctl.treadmill.unblock()
            
            % this needs to be non-blocking
            proc = obj.ctl.soloist.block_test();
            % proc = obj.ctl.soloist.listen_until(obj.back_limit, obj.forward_limit);
            
            pause(1)
            obj.ctl.play_velocity_waveform()
            
            proc.wait_for(0.1);
            
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