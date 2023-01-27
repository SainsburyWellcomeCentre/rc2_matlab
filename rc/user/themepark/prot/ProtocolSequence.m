classdef ProtocolSequence < handle
    % ProtocolSequence class for handling a sequence of trial objects.

    properties
        ctl % :class:`rc.main.RC2Controller` object controller.
        sequence = {} % Cell array containing objects of the trial classes.
        running = false; % Boolean specifying whether the sequence is running.
        abort = false; % Boolean specifying whether to abort the sequence.
        current_sequence % The currently running trial.
        current_reward_state = false % The state of reward randomization before the sequence.
        randomize_reward = false % whether to randomize the timing of the reward after the trial.
    end
    
    properties (SetObservable = true)
        current_trial = 1; % Current index of the trial running.
        forward_trials = 0; % Number of trials which have finished forward.
        backward_trials = 0; % Number of trials which have finished backward.
    end
    
    
    methods
        function obj = ProtocolSequence(ctl)
            % Constructor for a :class:`rc.prot.ProtocolSequence` class.
            %
            % :param ctl: a :class:`rc.main.RC2Controller` object.
        
            obj.ctl = ctl;
        end
        
        
        function add(obj, protocol)
            % Adds a trial object to the sequence.
            %
            % :param protocol: The trial to add to the protocol sequence. Should be a trial class (e.g. 'Coupled', 'EncoderOnly' etc.) with a valid `run` and `stop method and `handle_acquisition` and `wait_for_reward` properties.
        
            obj.sequence{end+1} = protocol;
        end
        
        
        function run(obj)
            % Run the sequence of trials. Runs the sequence of trials in :attr:`sequence` according to each trial's `run` method. Also starts NIDAQ acquisition and starts playing the sound.
        
            obj.prepare()
            
            h = onCleanup(@obj.cleanup);
            
            obj.ctl.play_sound();
            obj.ctl.prepare_acq();
            obj.ctl.start_acq();
            obj.running = true;
            
            for i = 1 : length(obj.sequence)
                
                obj.current_sequence = obj.sequence{i};
                obj.current_trial = i;
                
                % start running this protocol
                finished_forward = obj.sequence{i}.run();
                
                if obj.abort
                    obj.running = false;
                    obj.abort = false;
                    return
                end
                
                if finished_forward
                    obj.forward_trials = obj.forward_trials + 1;
                else
                    obj.backward_trials = obj.backward_trials + 1;
                end
            end
            
            % let cleanup handle the stopping
        end
        
        
        function prepare(obj)
            % Prepare for running a sequence of trials. Initializes internal variables, sets the reward to be randomized if necessary, sets :attr:`handle_acquisition`, :attr:`wait_for_reward` to false. The :attr:`wait_for_reward` property of the last trial is set to true.
        
            obj.current_trial = 1;
            obj.backward_trials = 0;
            obj.forward_trials = 0;
            
            obj.current_reward_state = obj.ctl.reward.randomize;
            obj.ctl.reward.randomize = obj.randomize_reward;
            
            % set run_once properties to false
            for i = 1 : length(obj.sequence)
                obj.sequence{i}.handle_acquisition = false;
                obj.sequence{i}.wait_for_reward = false;
            end
            
            % wait for reward to complete on last protocol
            obj.sequence{end}.wait_for_reward = true;
            
            % give warning if we are going to be loading onto teensy
            if isprop(obj.sequence{1}, 'direction')
                direction = cellfun(@(x)(x.direction), obj.sequence, 'uniformoutput', false);
                if length(unique(direction)) ~= 1
                    warning('direction of travel is not the same for all protocols')
                end
            end
        end
        
        
        function stop(obj)
            % Stops running the sequence of trials. Calls the `stop` method of the currently running trial.
        
            if isempty(obj.current_sequence)
                return
            end
            obj.abort = true;
            obj.current_sequence.stop();
            %delete(obj.current_sequence);
            obj.current_sequence = [];
            obj.ctl.reward.randomize = obj.current_reward_state;
        end

        
        function cleanup(obj)
            % Cleanup function for when `run` is completed.
        
            fprintf('running cleanup in protseq\n')
            obj.running = false;
            obj.ctl.soloist.stop();
            obj.ctl.block_treadmill()
            obj.ctl.vis_stim.off();
            obj.ctl.stop_acq();
            obj.ctl.stop_sound();
        end
    end
end