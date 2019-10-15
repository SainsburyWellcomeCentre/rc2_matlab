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
        sound
    end
    
    properties (SetObservable = true)
        acquiring = false
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
            obj.sound = Sound();
        end
        
        
        function delete(obj)
            delete(obj.plotting);
            obj.close()
        end
        
        
        function prepare_acq(obj)
            if obj.acquiring
                error('already acquiring data')
            end
            obj.saver.setup_logging();
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))
            obj.plotting.reset_vals();
        end
        
        
        function start_acq(obj)
            obj.ni.start_acq()
            obj.acquiring = true;
        end
        
        
        function h_callback(obj, ~, evt)
            obj.saver.log(evt.Data);
            obj.plotting.ni_callback(evt.Data);
        end
        
        
        function stop_acq(obj)
            obj.acquiring = false;
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
            obj.soloist.move_to(pos, false);
        end
        
        
        function load_velocity_waveform(obj, waveform)
            obj.ni.ao_write(waveform);
        end
        
        
        function play_velocity_waveform(obj)
            obj.ni.ao_start();
        end
        
        
        function set_save_save_to(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_save_to(str)
        end
        
        
        function set_save_prefix(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_prefix(str)
        end
        
        
        function set_save_suffix(obj, str)
            if obj.acquiring; return; end
            obj.saver.set_suffix(str)
        end
        
        
        function set_save_index(obj, val)
            if obj.acquiring; return; end
            obj.saver.set_index(val)
        end
        
        
        function set_save_enable(obj, val)
            if obj.acquiring; return; end
            obj.saver.set_enable(val)
        end
    end
end