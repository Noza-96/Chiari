%Create-planes journal
function TUI_setup_Fluent_case(DNS, cas, fileID)
    
    if nargin < 3
        fileID = fopen(fullfile(DNS.TUI_path,"setup_case_TUI.jou"), 'w');
    end
    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    fprintf(fileID,';setup case \n' );

    % boundary outlet is the oposite (top/bottom) of boundary inlet
    if DNS.inlet == "bottom"
        boundary_outlet = "top";
    else
        boundary_outlet = "bottom";
    end

    if DNS.sim == 3
        case_name  = DNS.geom + "_dx" + DNS.mesh_size+ "_zones" + DNS.version;
    else
        case_name  = DNS.geom + "_dx" + DNS.mesh_size + DNS.version;
    end

    % read case
    case_path = DNS.ansys_path +"/" + DNS.subject +"/inputs/case-files/"+ case_name + ".cas.gz"; 

    fprintf(fileID,"/file read-case "+case_path+"\n" );

    % disable flow-warnings (reverse-flow)
    fprintf(fileID,"/solve/set flow-warnings? no \n" );

    % setup viscous laminar model
    fprintf(fileID,"/define/models/viscous laminar yes\n" );


    named_expression (fileID, "rho", "1000 [kg/m^3]")
    named_expression (fileID, "mu", "0.0007 [kg/(m*s)]")

    % change material to CSF
    fprintf(fileID,'/define/materials/change-create air csf yes expression "rho" no no yes expression "mu" no no no yes q \n');

    % TODO: Update boundary conditions for DNS
    if ismember(DNS.sim, [0, 1]) 
        %bottom: zero pressure, tonsils: wall
        set_bc(fileID, DNS.inlet, "velocity-inlet")
        set_bc(fileID, boundary_outlet, "pressure-outlet")
        set_bc(fileID, "tonsils", "wall")
        set_bc(fileID, "cord", "wall")
    end
    
    % disable print-residuals
    fprintf(fileID,'/solve/monitors/residual/print? no q \n');
    
    % second-order transient simulation
    fprintf(fileID,'/define/models/unsteady-2nd-order? yes q \n');
    
    % Set pressure-velocity coupled scheme
    fprintf(fileID,'/solve/set p-v-coupling 24 q  \n');

    % import Q_b and Q_t
    fid = fopen(fullfile(cas.diransys_in, "flow-rates", "Q_bottom.txt"), 'r');  % Open the file for reading
    sstt = fread(fid, '*char')';  % Read the entire file as characters and transpose to row vector
    fclose(fid);
    named_expression (fileID, "Q_b", sstt)

    fid = fopen(fullfile(cas.diransys_in, "flow-rates", "Q_top.txt"), 'r');  % Open the file for reading
    sstt = fread(fid, '*char')';  % Read the entire file as characters and transpose to row vector
    fclose(fid);
    named_expression (fileID, "Q_t", sstt)
    

    % Create velocity inlet
    if DNS.sim == 0
        % independently of boundary inlet, uses flow rate at the bottom
        fid = fopen(fullfile(cas.diransys_in, "flow-rates", "Q_bottom.txt"), 'r');  % Open the file for reading
        sstt = fread(fid, '*char')';  % Read the entire file as characters and transpose to row vector
        fclose(fid);
        if DNS.inlet == "bottom"
            sign_normal_u = "+";
        elseif DNS.inlet == "top"
            sign_normal_u = "-";
        end

        named_expression (fileID, "Q_inlet", sstt)
        named_expression (fileID, "v_inlet", sign_normal_u+"Q_inlet/Area(['"+DNS.inlet+"'])")
        fprintf(fileID,"/define/boundary-conditions/velocity-inlet "+DNS.inlet+" no no yes yes no ""v_inlet"" no 0  q \n");
    end

    % Assign a penetration velocity in DNS.continuity to satisfy continuity
    if DNS.sim == 2
        named_expression (fileID, "v_" + DNS.continuity, "-(-Q_t + Q_b)/(Area(['" + DNS.continuity + "']))")
        fprintf(fileID,"/define/boundary-conditions/velocity-inlet " + DNS.continuity + " no no yes yes no ""v_" + DNS.continuity + """ no 0  q \n");
    end

    if DNS.sim == 3
        for zone_i = 1:(cas.Ncas-1)
            if zone_i < (cas.Ncas-1)
                fid = fopen(fullfile(cas.diransys_in, "flow-rates", "Q_"+zone_i+".txt"), 'r');  % Open the file for reading
                sstt = fread(fid, '*char')';  % Read the entire file as characters and transpose to row vector
                fclose(fid);
                named_expression (fileID, "Q_cord_"+zone_i, sstt)
            end
            if zone_i == 1
                sstt = "- Q_t + Q_cord_"+zone_i;
            elseif zone_i == cas.Ncas-1
                sstt = "- Q_cord_" + num2str(zone_i-1) + " + Q_b";
            else
                sstt = "- Q_cord_" + num2str(zone_i-1) + " + Q_cord_" + zone_i;
            end
            named_expression (fileID, "v_cord_" + zone_i, "-("+sstt+")/(Area(['cord_" + zone_i + "']))")
            fprintf(fileID,"/define/boundary-conditions/velocity-inlet cord_" + zone_i + " no no yes yes no ""v_cord_" + zone_i + """ no 0  q \n");
        end
    end

    if nargin < 3
        fclose(fileID);
    end

end

function named_expression (fileID,name, expression)

    TUI_sstt = sprintf('/define/named-expressions add "%s" definition "%s" q \n', ...
         name, expression);

    fprintf(fileID,TUI_sstt);
end

function set_bc(fileID, boundary_name, condition)
    fprintf(fileID,"/define/boundary-conditions/modify-zones/zone-type " + boundary_name + " " + condition + " q \n");
end
