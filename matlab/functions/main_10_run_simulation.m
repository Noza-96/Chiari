function main_10_run_simulation(cas, dat_PC, DNS_cases, n_cores)

    fprintf("10) CFD simulation:\n") 
    
    
    % Run simulations for each DNS case
    for k = 1:length(DNS_cases)
        tic; 

        DNS = loadDNSData(cas, DNS_cases{k});

        output_check = fullfile(DNS.path_out_report, DNS_cases{k} + "_report.out");

        if isfile(output_check)
            fprintf('- %s simulation already done! skipping to next case...\n', DNS_cases{k});
            continue;
        else
            fprintf('\n%s:\n', DNS_cases{k});
        end  
        

        % Create and run the ANSYS journal
        fileID = fopen(fullfile(cas.dir.ansys_in, "journals", DNS.case + ".jou"), 'w');
        
        fprintf('- Setting up Fluent case...\n');   
        % Setup simulation
        TUI_setup_Fluent_case(DNS, cas, fileID);

        fprintf('- Creating journals...\n');   
        % Create PCMRI surfaces and other necessary setups
        TUI_create_surfaces_journal(dat_PC, cas, DNS, fileID);
        
        % Add reports every time step
        TUI_reports_journal(DNS, fileID);

        fprintf('- Running CFD simulation...\n\n');   
        % run the simulation - add reports last cycle
        TUI_run_simulation(dat_PC, cas, DNS, fileID);

        runFluentSimulation(cas, DNS, DNS_cases{k}, n_cores);

        % Finalize after simulation
        elapsed_time = toc;
        finalizeSimulation(DNS, DNS_cases{k}, cas, elapsed_time);
    end
end

% Helper function to load DNS data
function DNS = loadDNSData(cas, case_name)
    load(fullfile(cas.dir.mat,'DNS', "DNS_" + case_name + ".mat"), 'DNS');
end

% Helper function to run the Fluent simulation through terminal
function runFluentSimulation(cas, DNS, case_name, n_cores)
    fluent_command = get_fluent_command(cas);
    fluent_cmd = """" + fluent_command + """" + " 3ddp -t" + n_cores + " -g -i """ + fullfile(DNS.ansys_path, "inputs", "journals", case_name + ".jou") + """";
    system(fluent_cmd); % Run with "> nul" to suppress terminal output
end

% Helper function to finalize simulation and save results
function finalizeSimulation(DNS, case_name, cas, elapsed_time)
    delete('fluent*'); % Delete temporary files
    movefile(case_name + "_report.out", fullfile(DNS.path_out_report, case_name + "_report.out"));
    fprintf("%s completed in %.2f seconds.\n", case_name, elapsed_time);

    % Save the simulation time
    DNS.time = elapsed_time;
    save(fullfile(cas.dir.mat, 'DNS', "DNS_" + DNS.case + ".mat"), 'DNS');
end



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
    case_path_gz = fullfile(DNS.ansys_path, "inputs", "case-files", case_name + ".cas.gz");
    case_path_cas = fullfile(DNS.ansys_path, "inputs", "case-files", case_name + ".cas");
    if isfile(case_path_gz)
        case_path = case_path_gz;
    elseif isfile(case_path_cas)
        case_path = case_path_cas;
    else
        error("- Case file not found: %s", case_name);
    end

    fprintf(fileID,"/file read-case " + correct_path(case_path) + "\n" );

    % disable flow-warnings (reverse-flow)
    fprintf(fileID,"/solve/set flow-warnings? no \n" );

    % setup viscous laminar model
    fprintf(fileID,"/define/models/viscous laminar yes\n" );


    named_expression (fileID, "rho", "1000 [kg/m^3]")
    named_expression (fileID, "mu", "0.0007 [kg/(m*s)]")

    % change material to CSF
    fprintf(fileID,'/define/materials/change-create air csf yes expression "rho" no no yes expression "mu" no no no yes q \n');

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
    fid = fopen(fullfile(cas.dir.ansys_in, "flow-rates", "Q_bottom.txt"), 'r');  
    sstt = fread(fid, '*char')';  
    fclose(fid);
    named_expression (fileID, "Q_b", sstt)

    fid = fopen(fullfile(cas.dir.ansys_in, "flow-rates", "Q_top.txt"), 'r');  
    sstt = fread(fid, '*char')';  
    fclose(fid);
    named_expression (fileID, "Q_t", sstt)
    

    % Create uniform velocity inlet
    if DNS.sim == 0
        % independently of boundary inlet, uses flow rate at the bottom
        fid = fopen(fullfile(cas.dir.ansys_in, "flow-rates", "Q_bottom.txt"), 'r');  
        sstt = fread(fid, '*char')'; 
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
                fid = fopen(fullfile(cas.dir.ansys_in, "flow-rates", "Q_"+zone_i+".txt"), 'r'); 
                sstt = fread(fid, '*char')';  
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

%Create-planes journal
function TUI_create_surfaces_journal(dat_PC, cas, DNS, fileID)

    if nargin < 4
        fileID = fopen(fullfile(DNS.TUI_path,"create_surfaces_journal_TUI.jou"), 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    fprintf(fileID,';create surfaces\n' );

    N = dat_PC.Ndat;
    
    % Create slices of PC measurements
    for loc = 2:N-1 %TODO: skip top and bottom locations
        XYZ = three_point_plane(dat_PC, loc);
        create_plane (fileID,XYZ,cas.locations{loc})
    end

    z_FM = dat_PC.pixel_coord{1}(:,:,3);
    z_FM = mean(z_FM(dat_PC.SAS.ROI{1}));
    % create axial planes 
    for Dz = DNS.Dz
        % Dz foramen with respect to top pcmri location
        Dz_foramen = (z_FM+(Dz-0.01))/1000; % [m]

         % create plane at the FM
        XYZ(:,3) = Dz_foramen;
        create_plane (fileID,XYZ,"FM-"+Dz)
    end

    if DNS.sim ~= 3
        % Create surface to export later
        zone_names = {'cord', 'dura', 'tonsils'};
        for k = 1:length(zone_names)
            fprintf(fileID,sprintf('/surface/zone-surface %s_s "%s" q \n', zone_names{k}, zone_names{k}));
        end
        fprintf(fileID,sprintf('/surface/group-surfaces %s () wall  q \n', strjoin(append(zone_names,'_s'),' ')));
    end
    if nargin < 4
        fclose(fileID);
    end
end


function create_plane (fileID, XYZ, sstt)
    fprintf(fileID,"/surface/plane-surface "+sstt+" three-points ");
    % Loop through the points (1 to 3) and print their XYZ coordinates
    for point = 1:3
        % Print each coordinate  
        fprintf(fileID, '%f %f %f ', XYZ(point, 1), XYZ(point, 2), XYZ(point, 3)); % [m]
    end
    fprintf(fileID,"no\n");
end

function XYZ = three_point_plane(dat_PC, index)

    xyz = dat_PC.pixel_coord{index}*1e-3; %m
    
    % xyz coordinates
    x = reshape(xyz(:,:,1),[],1);
    y = reshape(xyz(:,:,2),[],1);
    z = reshape(xyz(:,:,3),[],1);
    
    % coordinates to define the plane
    x_coords = transpose([x(1), x(floor(end/2)), x(end)]);
    y_coords = transpose([y(1), y(floor(end/2)), y(end)]);
    z_coords = transpose([z(1), z(floor(end/2)), z(end)]);

    XYZ = [x_coords,y_coords,z_coords];

end


function TUI_reports_journal(DNS, fileID)

    if nargin < 2
        fileID = fopen(DNS.TUI_path+"/reports_journal_TUI.jou", 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    if ~exist(DNS.path_out_report, 'dir')
        mkdir(DNS.path_out_report);
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
    
    for Dz = DNS.Dz
        fprintf(fileID,"/solve/report-definitions/add p_FM-" + Dz + "  surface-areaavg field pressure surface-names FM-" + Dz + " () q \n" );
    end

    % report files
    variables = ['flow-time', 'u_max', "q_" + inlet_locations(1:end), "p_FM-" + DNS.Dz];
    report_file (fileID, variables, DNS.case, 1);

    if nargin < 2
        fclose(fileID);
    end
    
end

function report_file (fileID, variables, report_case, freq)

    TUI_sstt = sprintf('/solve/report-files/add %s_report frequency %d name "%s_report" report-defs %s () print? yes file-name "%s_report" q \n', ...
         report_case, freq, report_case, strjoin(variables, ' '), report_case);

    fprintf(fileID,TUI_sstt);
end

function TUI_run_simulation(dat_PC, cas, DNS, fileID)

    if nargin < 4
        fileID = fopen(DNS.TUI_path+"/run_simulation_TUI.jou", 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    fprintf(fileID,';run simulation \n' );

    profile_dir = fullfile(DNS.ansys_path, "inputs", "profiles", "ts_" + DNS.ts_cycle);
    surface_path = fullfile(DNS.ansys_path, "outputs", "surface_mesh");
    
    time_step = dat_PC.T{end}/DNS.ts_cycle;
    fprintf(fileID,"time-step "+time_step+" \n");

    if DNS.sim == 0
        prof_bound = {}; % Do not assign profile but impose flow rate
    elseif DNS.sim == 1
        prof_bound = {DNS.inlet}; % Only assign profile to inlet
    elseif ismember(DNS.sim, [2, 3])
        prof_bound = {"bottom", "top"}; % Two inlets
    end
  
    for k=1:DNS.cycles
        if k == DNS.cycles
            TUI_last_cycle_report_journal(DNS, fileID)
        end
        for n = 1:DNS.ts_cycle   


            for boundary = prof_bound
                % load profile data
                fprintf(fileID,"/file/read-profile """ + correct_path(fullfile(profile_dir, boundary{1} + "_prof_" + n + ".csv""")) + "\n");

                % setup inlet velocity boundary condition 
                ID_prof = boundary+"_vel";
                fprintf(fileID,"/define/boundary-conditions/velocity-inlet "+boundary{1}+" no no yes yes yes no """+ID_prof+""" ""u1"" no 0. \n");
            end
            
            % We have to proceed time step by time step
            if (k==1) && (n==1)
                % hybrid initialization
                fprintf(fileID,"/solve/initialize/ initialize-flow \n");
                fprintf(fileID,"/solve/initialize/hyb-initialization yes \n");

                if DNS.sim ~=3
                    % export surface mesh
                    fprintf(fileID, sprintf("/file/export ascii %s wall () no () ok  q \n", correct_path(surface_path)));
                end
            end

            fprintf(fileID,";" + DNS.case + ": iteration " + n + "/" + DNS.ts_cycle + " cycle "+k+"/"+DNS.cycles+"\n" );

            fprintf(fileID,"/solve/dual-time-iterate 1 " + DNS.iterations_ts + " ok ok \n");

        end         
    end

    % close fluent in the terminal
	fprintf(fileID,"exit ok \n");
    fclose(fileID);

end

function TUI_last_cycle_report_journal(DNS, fileID)
% Last cycle - Save DNS.fields at pcmri locations every time-step

    fprintf(fileID,';last cycle reports \n' );
    
    report_name = DNS.case + '_report';
    report_path = fullfile(DNS.ansys_path, "outputs", DNS.case, report_name);

    frequency = 1;
    comma = 'no'; % Delimiter/Comma?
    Cell_centered = 'no'; % Location/Cell-Centered?
    export_every = 'time-step'; % Export data every: ("time-step" "flow-time")


    fields_str = strjoin(DNS.fields, ' '); % Concatenate fields with space delimiter
    locations_str = strjoin(DNS.slices.locations, ' '); % Concatenate locations with space delimiter

    TUI_sstt = sprintf('/file/transient-export/ascii "%s" %s () %s q %s %s %s "%s" %d time-step \n', ...
    correct_path(report_path), locations_str, fields_str, Cell_centered, comma, report_name, export_every, frequency);

    fprintf(fileID,TUI_sstt);
    
end
