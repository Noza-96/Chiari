function TUI_last_cycle_report_journal(DNS, fileID)
% Last cycle - Save DNS.fields at pcmri locations every time-step

    fprintf(fileID,';last cycle reports \n' );
    
    report_name = DNS.case + '_report';
    folder = DNS.ansys_path+"/"+DNS.subject+"/outputs/"+DNS.case;
    directory = folder + "/" + report_name;


    frequency = 1;
    comma = 'no'; % Delimiter/Comma?
    Cell_centered = 'no'; % Location/Cell-Centered?
    export_every = 'time-step'; % Export data every: ("time-step" "flow-time")

    % Join fields and locations into a single string
    fields_str = strjoin(DNS.fields, ' '); % Concatenate fields with space delimiter
    locations_str = strjoin(DNS.slices.locations, ' '); % Concatenate locations with space delimiter
    % Build the string using sprintf
    TUI_sstt = sprintf('/file/transient-export/ascii "%s" %s () %s q %s %s %s "%s" %d time-step \n', ...
    directory, locations_str, fields_str, Cell_centered, comma, report_name, export_every, frequency);

    fprintf(fileID,TUI_sstt);
    
end