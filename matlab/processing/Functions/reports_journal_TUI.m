function reports_journal_TUI(cas, report_case)
    fileID = fopen(cas.diransys_in+"/reports_journal_TUI.jou", 'w');
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    fprintf(fileID,'/solve/report-definitions/add pilot volume-max field velocity-magnitude zone-names fluid () q \n' );
    report_file (fileID, {'flow-time'}, 'pilot', 1)
    fprintf(fileID,'/solve/report-plot/add pilot q \n' );
    % delete previous reports to avoid conflicts
        fprintf(fileID,"/solve/report-plots delete-all yes \n");
        fprintf(fileID,"/solve/report-files delete-all yes \n");
        fprintf(fileID,"/solve/report-definitions delete-all yes \n");


    fprintf(fileID,"/solve/report-definitions delete-all yes \n");
    % report definitions         
        % u_max
        fprintf(fileID,'/solve/report-definitions/add u_max volume-max field velocity-magnitude zone-names fluid () q \n' );
        % flow rate bottom
        fprintf(fileID,'/solve/report-definitions/add q_bottom surface-volumeflowrate surface-names bottom () q \n' );
        % Create expression
        expression =  "Average(StaticPressure,['fm'], Weight ='Area') - Average(StaticPressure,['fm-25'], Weight ='Area')";
        TUI_sstt = sprintf('/solve/report-definitions/add dp single-val-expression define "%s" q \n', expression);
        fprintf(fileID,TUI_sstt);

    % report files
    variables = {'flow-time', 'dp','q_bottom', 'u_max'};
    report_file (fileID, variables, report_case, 1)




end

function report_file (fileID, variables, cas, freq)

    TUI_sstt = sprintf('/solve/report-files/add %s_variables frequency %d name "%s_variables" report-defs %s () q \n', ...
         cas, freq, cas, strjoin(variables, ' '));

    fprintf(fileID,TUI_sstt);
end