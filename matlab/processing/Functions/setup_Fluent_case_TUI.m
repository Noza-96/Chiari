%Create-planes journal
function setup_Fluent_case_TUI(DNS, fileID)

    if nargin < 2
        fileID = fopen(fullfile(DNS.TUI_path,"setup_case_TUI.jou"), 'w');
    end
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    fprintf(fileID,';setup case \n' );

    % read case
    case_path = DNS.ansys_path +"/" + DNS.subject +"/inputs/"+ DNS.case + "_0.cas.gz";

    fprintf(fileID,"/file read-case "+case_path+"\n" );

    % setup viscous laminar model
    fprintf(fileID,"/define/models/viscous laminar yes\n" );


    named_expression (fileID, "rho", "1000 [kg/m^3]")
    named_expression (fileID, "mu", "0.0007 [kg/(m*s)]")

    % change material to CSF
    fprintf(fileID,'/define/materials/change-create air csf yes expression "rho" no no yes expression "mu" no no no yes q \n');
    
    % second-order transient simulation
    fprintf(fileID,'/define/models/unsteady-2nd-order? yes q \n');
    
    % Set pressure-velocity coupled scheme
    fprintf(fileID,'/solve/set p-v-coupling 24 q  \n');
    if contains(DNS.case,"c2") 
        named_expression (fileID, "v_cord", "-(MassFlow(['top'])+MassFlow(['bottom']))/(rho*Area(['cord']))")
        fprintf(fileID,'/define/boundary-conditions/velocity-inlet cord no no yes yes no "v_cord" no 0  q \n');
    end

    if nargin < 2
        fclose(fileID);
    end

end

function named_expression (fileID,name, expression)

    TUI_sstt = sprintf('/define/named-expressions add "%s" definition "%s" q \n', ...
         name, expression);

    fprintf(fileID,TUI_sstt);
end