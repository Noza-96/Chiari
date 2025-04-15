function TUI_run_simulation(dat_PC, cas, DNS, fileID)

    if nargin < 4
        fileID = fopen(DNS.TUI_path+"/run_simulation_TUI.jou", 'w');
        fprintf(fileID,'/file/set-tui-version "24.1"\n' );
    end

    fprintf(fileID,';run simulation \n' );

    profile_dir = DNS.ansys_path+"/"+cas.subj+"/inputs/profiles/";
    surface_path = DNS.ansys_path+"/"+cas.subj+"/outputs/surface_mesh";

    % set time-step
    time_step = dat_PC.T{end}/DNS.ts_cycle;
    fprintf(fileID,"time-step "+time_step+" \n");

    if DNS.sim == 0
        prof_bound = {}; % Do not assign profile but impose flow rate
    elseif DNS.sim == 1
        prof_bound = {"bottom"}; % Only assign profile to bottom
    elseif DNS.sim == 2
        prof_bound = {"bottom", "top"}; % Two inlets
    end

        
    for k=1:DNS.cycles
        for n = 1:DNS.ts_cycle   
            for boundary = prof_bound
                % load profile data
                fprintf(fileID,"/file/read-profile """+profile_dir+""+boundary{1}+"_prof_"+n+".csv"" \n");

                % setup inlet velocity boundary condition 
                ID_prof = boundary+"_vel";
                fprintf(fileID,"/define/boundary-conditions/velocity-inlet "+boundary{1}+" no no yes yes yes no """+ID_prof+""" ""u1"" no 0. \n");
            end
            
            % We have to proceed time step by time step
            if (k==1) && (n==1)
                % hybrid initialization
                fprintf(fileID,"/solve/initialize/ initialize-flow \n");
                fprintf(fileID,"/solve/initialize/hyb-initialization yes \n");

                % export surface mesh
                fprintf(fileID,sprintf("/file/export ascii %s wall () no () ok  q \n", surface_path));

                % run first iteration, with yes to continue
                fprintf(fileID,"/solve/dual-time-iterate 1 "+DNS.iterations_ts+" ok ok \n");
            else
                % next iterationsss
                fprintf(fileID,"/solve/dual-time-iterate 1 "+DNS.iterations_ts+" ok ok \n");
            end
        end         
    end

    % close fluent in the terminal
	fprintf(fileID,"exit ok \n");
    fclose(fileID);

end