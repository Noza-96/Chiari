function save_every_time_step_TUI (fileID, cas, ansys_dir, fields, locations, filename)
    % SETUP
    
    directory = ansys_dir+"/"+cas.subj+"/outputs/"+filename;

    frequency = 1;
    comma = 'no'; % Delimiter/Comma?
    Cell_centered = 'no'; % Location/Cell-Centered?
    export_every = 'time-step'; % Export data every: ("time-step" "flow-time")
    
    % Join fields and locations into a single string
    fields_str = strjoin(fields, ' '); % Concatenate fields with space delimiter
    locations_str = strjoin(locations, ' '); % Concatenate locations with space delimiter
    
    % Build the string using sprintf
    TUI_sstt = sprintf('/file/transient-export/ascii "%s" %s %s q %s %s %s "%s" %d time-step \n', ...
    directory, locations_str, fields_str, Cell_centered, comma, filename, export_every, frequency);

    fprintf(fileID,TUI_sstt);
end