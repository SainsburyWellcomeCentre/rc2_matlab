classdef Controller < handle
    
    properties
        
        config
        ni
        teensy
        soloist
        reward
        treadmill
        multiplexer
        plotting
        saver
        caller
    end
    
    
    
    methods
        function obj = Controller(config, home_prompt)
            
            VariableDefault('home_prompt', true)
            
            obj.config = config;
            obj.ni = NI(config);
            obj.teensy = Teensy(config);
            obj.soloist = Soloist(config, home_prompt);
            obj.reward = Reward(obj.ni, config);
            obj.treadmill = Treadmill(obj.ni, config);
            obj.multiplexer = Multiplexer(obj.ni, config);
            obj.plotting = Plotting(config);
            obj.saver = Saver(config);
        end
        
        
        function delete(obj)
            obj.close()
        end
        
        
        function run(obj, prot_caller)
           obj.caller =  prot_caller;
           obj.teensy.load(prot_caller.direction);
           obj.multiplexer.listen_to(prot_caller.vel_source);
           obj.prepare_acq();
           obj.start_acq();
        end
        
        
        function prepare_acq(obj)
            obj.saver.setup_logging();
            obj.ni.ai.prepare(@(x, y)obj.h_callback(x, y))
            obj.plotting.reset_vals();
        end
        
        
        function h_callback(obj, ~, evt)
            obj.saver.log(evt.Data);
            obj.plotting.ni_callback(evt.Data);
        end
        
        
        function start_acq(obj)
            obj.ni.start_acq()
        end
        
        
        function stop_acq(obj)
            obj.ni.stop_acq();
            obj.saver.stop_logging();
        end
        
        
        function close(obj)
            obj.ni.close()
        end
        
        
        function give_reward(obj)
            obj.reward.give_reward();
        end
        
        
        function block_treadmill(obj)
            obj.treadmill.block()
        end
        
        
        function unblock_treadmill(obj)
            obj.treadmill.unblock()
        end
        
        
        function move_to(obj, pos)
            proc = obj.soloist.move_to(pos, false);
            proc.wait_for(0.5);
        end
        
        
        function load_velocity_waveform(obj, waveform)
            obj.ni.ao_write(waveform);
        end
        
        
        function play_velocity_waveform(obj)
            obj.ni.ao_start();
        end
    end
end