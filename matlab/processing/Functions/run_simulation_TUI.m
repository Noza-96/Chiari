function run_simulation_TUI(dat_PC, cas, cycles, iterations_time_step)

    Nt = 100; 
 
    fileID = fopen(cas.diransys_in+"/run_simulation_TUI.jou", 'w');
    profile_dir = cas.dir_fullpath_ansys+"/"+cas.subj+"/inputs/profiles/";

    fprintf(fileID,'/file/set-tui-version "24.1"\n' );

    % set time-step
    time_step = dat_PC.T{end}/100;
    fprintf(fileID,"time-step "+time_step+" \n");

        
    for k=1:cycles
        for n = 1:Nt   
            % load profile data
            fprintf(fileID,"/file/read-profile """+profile_dir+"bottom_prof_"+n+".csv"" \n");
            % setup inlet velocity boundary condition 
            boundary = "bottom";
            ID_prof = boundary+"_vel";
            fprintf(fileID,"/define/boundary-conditions/velocity-inlet "+boundary+" no no yes yes yes no """+ID_prof+""" ""u1"" no 0. \n");

            if (k==1) && (n==1)
                % hybrid initialization
                fprintf(fileID,"/solve/initialize/hyb-initialization yes \n");

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