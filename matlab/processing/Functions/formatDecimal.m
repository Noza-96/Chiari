function formattedStrs = formatDecimal(numArray)
    formattedStrs = cell(1, length(numArray)); % Preallocate cell array
    
    for i = 1:length(numArray)
        % Convert number to string without scientific notation
        strNum = sprintf('%.10f', numArray(i));  
        strNum(strNum == '.') = ''; % Remove decimal point
        
        % Remove trailing zeros
        strNum = regexprep(strNum, '0+$', '');
        
        % Ensure at least one leading zero remains
        if isempty(strNum)
            formattedStrs{i} = '0';
        else
            formattedStrs{i} = strNum;
        end
    end
end