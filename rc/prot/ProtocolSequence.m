classdef ProtocolSequence < handle
    
    properties
        ctl
        sequence = {}
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
            
            obj.ctl.play_sound();
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
            
            for i = 1 : length(obj.sequence)
                obj.sequence{i}.prepare_as_sequence(obj.sequence, i)
                obj.sequence{i}.run();
            end
            
            obj.ctl.stop_acq();
            obj.ctl.stop_sound();
        end
        
        
        function prepare(obj)
            
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
    end
end