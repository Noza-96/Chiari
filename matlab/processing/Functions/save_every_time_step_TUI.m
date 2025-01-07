function save_every_time_step_TUI (cas, fields, locations, filename)
    % SETUP
    fileID = fopen(cas.diransys_in+"/save_every_time_step_TUI.jou", 'w');

    directory = cas.dir_fullpath_ansys+"/"+cas.subj+"/outputs/"+filename;

    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

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

    fclose(fileID);
end