classdef Agatha_04_vis < handle

    properties
    
        cycles_per_degree       = 0.02;
        cycles_per_s_all        = [1.5, 2, 3, 4, 6];  %% which TFs do we need?

        n_s_plus_trials
        n_s_minus_trials
        n_trials
        s_plus
        cycles_per_s
        
    end
    
    methods
    
        function obj = Agatha_04_vis()
    
            obj.n_s_plus_trials         = 10;
            obj.n_s_minus_trials        = 10;
            obj.n_trials                = obj.n_s_plus_trials + obj.n_s_minus_trials;
    
        end
    
        function obj = vis_stim_type(obj, type_id)
            if strcmp(type_id,'1')
                obj.s_plus = true;
                obj.cycles_per_s = [obj.cycles_per_s_all([1, 1])];
            elseif strcmp(type_id,'2')
                    obj.s_plus = false;
                    obj.cycles_per_s = [obj.cycles_per_s_all([1, 4])];
            elseif strcmp(type_id,'3')
                        obj.s_plus = false;
                        obj.cycles_per_s = [obj.cycles_per_s_all([4, 1])];
            end  
        end
    
    
    end

end
