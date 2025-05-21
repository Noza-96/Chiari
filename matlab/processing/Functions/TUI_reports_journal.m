function TUI_reports_journal(cas, DNS, fileID)

    if nargin < 3
        fileID = fopen(DNS.TUI_path+"/reports_journal_TUI.jou", 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    inlet_locations = ["bottom", "top", "tonsils"];

    fprintf(fileID,';reports \n' );

    % create dummy files
    fprintf(fileID,'/solve/report-definitions/add pilot volume-max field velocity-magnitude zone-names fluid () q \n' );
    report_file (fileID, {'flow-time'}, 'pilot', 1)
    fprintf(fileID,'/solve/report-plot/add pilot q \n' );

    % delete previous reports to avoid conflicts
    fprintf(fileID,"/solve/report-plots delete-all yes \n");
    fprintf(fileID,"/solve/report-files delete-all yes \n");
    fprintf(fileID,"/solve/report-definitions delete-all yes \n");

    % report definitions         
    % u_max
    fprintf(fileID,'/solve/report-definitions/add u_max volume-max field velocity-magnitude zone-names fluid () q \n' );
    % flow rate inlet locations
    for location = inlet_locations
        fprintf(fileID,"/solve/report-definitions/add q_" + location + "  surface-volumeflowrate surface-names " + location + " () q \n" );
    end
    
    for Dz = 5:5:50
        fprintf(fileID,"/solve/report-definitions/add p_FM-" + Dz + "  surface-areaavg field pressure surface-names FM-" + Dz + " () q \n" );
    end

    % report files
    variables = ['flow-time', 'u_max', "q_" + inlet_locations(1:end), "p_FM-" + [5:5:50]];
    report_file (fileID, variables, DNS.case, 1);

    %% Save velocity and pressure at specific locations every time-step
    report_name = DNS.case + '_report';

    folder = DNS.ansys_path+"/"+cas.subj+"/outputs/"+DNS.case;
    directory = folder + "/" + report_name;

    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

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

    if nargin < 3
        fclose(fileID);
    end
    
end

function report_file (fileID, variables, report_case, freq)

    TUI_sstt = sprintf('/solve/report-files/add %s_report frequency %d name "%s_report" report-defs %s () print? yes file-name "%s_report" q \n', ...
         report_case, freq, report_case, strjoin(variables, ' '), report_case);

    fprintf(fileID,TUI_sstt);
end