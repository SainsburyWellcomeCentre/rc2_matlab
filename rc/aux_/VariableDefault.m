function VariableDefault(varString, value)
    % Set a variable within a function, giving it a default if it doesn't already exist or is empty.
    %
    % :param varString: String containing the name of the variable.
    % :param value: Default value of the variable.
    %
    % Credit goes to Richie Cotton's 'SetDefaultValue' function on the
    % MathWork's File Exchange.
    % https://uk.mathworks.com/matlabcentral/fileexchange/27056-set-default-values


    if ~evalin('caller', sprintf('exist(''%s'', ''var'')', varString))
        assignin('caller', varString, value);
    end

    if evalin('caller', sprintf('isempty(%s)', varString))
        assignin('caller', varString, value);
    end