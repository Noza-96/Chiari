function reports_journal_TUI(dat_PC, cas)
    fileID = fopen(cas.diransys_in+"/reports_journal_TUI.jou", 'w');
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    name_expression = "dp_FM"; 
    definition =  "Average(StaticPressure,['fm'], Weight ='Area') - Average(StaticPressure,['fm-25'], Weight ='Area')";
    named_expression (fileID, name_expression, definition)

%% This file is to be completed!



end

function named_expression (fileID, name, definition)

    TUI_sstt = sprintf('/define/named-expressions/add "%s" definition "%s" \n', ...
        name, definition);

    fprintf(fileID,TUI_sstt);

end