function check_valid_case(case_names)
    valid_cases = ["c0","c1","c2","b0","b1","cn0","cn1","cn2","bn0","bn1"];

    % Loop through each case to see if its valid
    for i = 1:length(case_names)
        this_case = string(case_names{i});
        if ~ismember(this_case, valid_cases)
            error("Invalid case name: '%s'. Must be one of: %s", ...
                  this_case, strjoin(valid_cases, ", "));
        end
    end
end