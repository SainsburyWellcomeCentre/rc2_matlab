classdef ProtocolSequence < handle
    
    properties
        ctl
        sequence = {}
        running = false;
        abort = false;
        current_sequence
    end
    
    properties (SetObservable = true)
        current_trial = 0;
    end
    
    
    methods
        function obj = ProtocolSequence(ctl)
            obj.ctl = ctl;
        end
        
        function add(obj, protocol)
            obj.sequence{end+1} = protocol;
        end
        
        
        function run(obj)
            
            obj.prepare()
            
            h = onCleanup(@obj.cleanup);
            
            obj.ctl.play_sound();
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
            obj.running = true;
            
            for i = 1 : length(obj.sequence)
                obj.current_sequence = obj.sequence{i};
                obj.current_trial = i;
                
                % this is quite specific for the vestibular condition...
                if isa(obj.sequence{i}, 'StageOnly') && i > 1
                    obj.sequence{i}.prepare_as_sequence(obj.sequence{i-1}.log_trial_fname)
                end
                
                % start running this protocol
                obj.sequence{i}.run();
                
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    return
                end
            end
            
            % let cleanup handle the stopping
        end
        
        
        function prepare(obj)
            
            obj.current_trial = 0;
            
            % set run_once properties to false
            for i = 1 : length(obj.sequence)
                obj.sequence{i}.handle_acquisition = false;
                obj.sequence{i}.wait_for_reward = false;
            end
            
            % wait for reward to complete on last protocol
            obj.sequence{end}.wait_for_reward = true;
            
            % give warning if we are going to be loading onto teensy
            direction = cellfun(@(x)(x.direction), obj.sequence, 'uniformoutput', false);
            if length(unique(direction)) ~= 1
                warning('direction of travel is not the same for all protocols')
            end
        end
        
        
        function stop(obj)
            
            if isempty(obj.current_sequence)
                return
            end
            obj.abort = true;
            obj.current_sequence.stop();
            obj.current_sequence = [];
        end
        
        
        function cleanup(obj)
            
            obj.running = false;
            obj.ctl.soloist.abort();
            obj.ctl.block_treadmill()
            obj.ctl.stop_acq();
            obj.ctl.stop_sound();
        end
    end
end