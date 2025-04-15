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
        % Create expression
        expression =  "Average(StaticPressure,['foramen_magnum'], Weight ='Area') - Average(StaticPressure,['foramen_magnum-"+num2str(DNS.delta_h_FM)+"'], Weight ='Area')";
        TUI_sstt = sprintf('/solve/report-definitions/add dp single-val-expression define "%s" q \n', expression);
        fprintf(fileID,TUI_sstt);

    % report files
    variables = ['flow-time', 'dp',"q_"+inlet_locations(1), "q_"+inlet_locations(2), "q_"+inlet_locations(3), 'u_max'];
    report_file (fileID, variables, DNS.case, 1);

    %% Save verlocity and pressure at specific locations every time-step
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

    TUI_sstt = sprintf('/solve/report-files/add %s_variables frequency %d name "%s_variables" report-defs %s () print? yes q \n', ...
         report_case, freq, report_case, strjoin(variables, ' '));

    fprintf(fileID,TUI_sstt);
end