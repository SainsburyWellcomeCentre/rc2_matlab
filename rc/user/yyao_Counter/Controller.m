classdef Controller < handle
    
    properties
        
        
        tic
        ni
        
    end
    
    
    properties (SetObservable = true, SetAccess = private, Hidden = false)
        
        acquiring = false
        acquiring_preview = false
        experiment_running = false
        version = '1.0'
    end
    
    
    
    methods
        
        function obj = Controller(config)
        %%obj = RC2_DoubleRotation_Controller(config)
        %   Main class for interfacing with the rollercoaster setup.            
        %       config - configuration structure containing necessary           
        %           parameters for setup - usually this is created with         
        %           config_default, but of course you can define your own
        %           config structure
        %   For information on each property see the related class.             
            
            
            obj.tic = tic;  
            obj.ni = NI(config); 
            
        end
        
        
        function delete(obj)
            
            % make sure that all devices are stopped properly
            obj.stop_acq()
            obj.ni.close()
        end
        
        
        %% Experiment
        function start_experiment(obj)
%             h = onCleanup(@obj.cleanup); 
            obj.prepare_acq();   
            obj.start_acq();
            obj.experiment_running = true;
        end

        function stop_experiment(obj)
            obj.cleanup();
        end

        function cleanup(obj)
            fprintf('running cleanup in protseq\n')
            obj.experiment_running = false;
            obj.stop_acq();
        end


        %% NIDAQ
        function set_ni_ao_idle(obj, solenoid_state, gear_mode)
            
            % Given the state of the setup, provided by arguments,
            % get the *EXPECTED* offset to apply on the NI AO, to prevent
            % movement on the visual stimulus.
            offset = obj.offsets.get_ni_ao_offset(solenoid_state, gear_mode);
            
            % set the idle voltage on the NI
            obj.ni.ao.idle_offset = repmat(offset, 1, length(obj.ni.ao.chan));
            
            % apply the voltage
            obj.ni.ao.set_to_idle();
        end
        
        
        
        function val = ni_ai_rate(obj)
            val = obj.ni.ai_rate();  % 10000
        end

        function abort_ao_task(obj)
            obj.ni.ao.stop();
%             obj.ni.ao.close();
        end

        

        %% Protocol
        
        function h_preview_callback(obj, ~, evt)

        end
        
        function prepare_acq(obj)   
            
            if obj.acquiring || obj.acquiring_preview
                error('already acquiring data')
                return %#ok<UNRCH>
            end
            
            obj.ni.prepare_acq(@(x, y)obj.h_callback(x, y))                    
        end
        
        
        function start_acq(obj)    
            
            % if already acquiring don't do anything
            if obj.acquiring || obj.acquiring_preview; return; end
            
            % start the NI-DAQ device and set acquiring flag to true
            obj.ni.start_acq()      
            obj.acquiring = true;
        end
        
        
        function h_callback(obj, ~, evt)   
            
        end
        
        
        function stop_acq(obj)
            if ~obj.acquiring; return; end
            if obj.acquiring_preview; return; end
            obj.acquiring = false;
            obj.ni.stop_acq(); 
        end
        
       
        
    end
end