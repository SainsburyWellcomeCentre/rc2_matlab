classdef Controller < handle
    
    properties
        
        ni
        teensy
        soloist
        reward
        treadmill
        multiplexer
        plotting
        saver
        trial_save
        sound
    end
    
    properties (SetAccess = private)
        position = 0;
        integrate_on = false;
        dt
    end
    
    properties (SetObservable = true, SetAccess = private, Hidden = true)
        acquiring = false
    end
    
    
    
    methods
        function obj = Controller(config, home_prompt)
            
            VariableDefault('home_prompt', true)
            
            obj.ni = NI(config);
            obj.teensy = Teensy(config);
            obj.soloist = Soloist(config, home_prompt);
            obj.reward = Reward(obj.ni, config);
            obj.treadmill = Treadmill(obj.ni, config);
            obj.multiplexer = Multiplexer(obj.ni, config);
            obj.plotting = Plotting(config);
            obj.saver = Saver(config);
            obj.sound = Sound();
            obj.position = Position(config);
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
            %TODO: convert data ONCE here and pass this to functions
            obj.saver.log(evt.Data);
            obj.plotting.ni_callback(evt.Data);
            obj.position.integrate(evt.Data(:, 1));
        end
        
        
        function stop_acq(obj)
            if ~obj.acquiring; return; end
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
        
        
        %%% TRIAL LOGGING
        function fname = start_logging_single_trial(obj)
            fname = obj.saver.start_logging_single_trial();
        end
        
        
        function stop_logging_single_trial(obj)
            obj.saver.stop_logging_single_trial()
        end
        
        
        function integrate_until(obj, back, forward)
            % check limits here
            obj.position.integrate_until(back, forward);
        end
        
        
        function cfg = get_config(obj)
            
            cfg.saving.save_to = obj.saver.save_to;
            cfg.saving.prefix = obj.saver.save_to;
            cfg.saving.suffix = obj.saver.save_to;
            cfg.saving.index = obj.saver.index;
            cfg.saving.ai_min_voltage = obj.saver.ai_min_voltage;
            cfg.saving.ai_max_voltage = obj.saver.ai_max_voltage;
        end
    end
end