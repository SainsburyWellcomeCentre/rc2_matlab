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
        
        
        function run(obj, prot_caller)
           obj.caller =  prot_caller;
           obj.prepare_acq()
           obj.start_acq()
        end
        
        
        function prepare_acq(obj)
            obj.saver.save()
            obj.ni.ai.prepare(1000, @(x, y)obj.plotting.ni_callback(x, y))
        end
        
        
        function start_acq(obj)
            obj.ni.start_acq()
        end
        
        
        function stop_acq(obj)
            obj.ni.stop_acq()
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
            obj.soloist.move_to(pos, false);
        end
    end
end