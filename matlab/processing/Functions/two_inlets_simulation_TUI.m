function two_inlets_simulation_TUI(dat_PC, cas, cycles, iterations_time_step, ts_cycle, ansys_path, TUI_path)
 
    fileID = fopen(TUI_path+"/two_inlets_simulation_TUI.jou", 'w');
    profile_dir = ansys_path+"/"+cas.subj+"/inputs/profiles/";
    surface_path = ansys_path+"/"+cas.subj+"/outputs/surface_mesh";

    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    % set time-step
    time_step = dat_PC.T{end}/ts_cycle;
    fprintf(fileID,"time-step "+time_step+" \n");

        
    for k=1:cycles
        for n = 1:ts_cycle   
            for boundary = {"bottom", "top"}
                % load profile data
                fprintf(fileID,"/file/read-profile """+profile_dir+""+boundary{1}+"_prof_"+n+".csv"" \n");
                % setup inlet velocity boundary condition 
                ID_prof = boundary+"_vel";
                fprintf(fileID,"/define/boundary-conditions/velocity-inlet "+boundary{1}+" no no yes yes yes no """+ID_prof+""" ""u1"" no 0. \n");
            end
            if (k==1) && (n==1)
                % hybrid initialization
                fprintf(fileID,"/solve/initialize/hyb-initialization yes \n");

                % export surface mesh
                fprintf(fileID,sprintf("/file/export ascii %s wall () no () ok  q \n",surface_path));

                % run first iteration, with yes to continue
                fprintf(fileID,"/solve/dual-time-iterate 1 "+iterations_time_step+" ok \n \n");
            else
                % next iterations
                fprintf(fileID,"/solve/dual-time-iterate 1 "+iterations_time_step+" 1 ok ok \n \n");
            end
        end
    end

    fclose(fileID);
end