classdef Test < handle
    
    properties (SetObservable = true, SetAccess = private, Hidden = true)
        acquiring = true
    end
    
    methods
        function obj = Test()
        end
    end
end