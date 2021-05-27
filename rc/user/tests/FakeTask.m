classdef FakeTask
    
    properties
        Rate = 10000
    end
    
    methods
        
        function val = isvalid(~)
            val = false;
        end
    end
end
