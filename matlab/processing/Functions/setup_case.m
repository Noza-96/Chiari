function [DNS_cases, cas, dat_PC] = setup_case(subject, session, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM, ansys_path)

    load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"), 'cas','dat_PC');
    
    DNS_cases = cell(length(case_name),length(mesh_size));
    
    % Check if it is the first time to run postprocessing or ts_cycle!=100
    if isempty(dir(fullfile(cas.dirmat, 'DNS*'))) || ts_cycle ~= 100
        disp('first time to run this subject, creating files...')

        % Create CSV files with velocity field information and pcmri.mat
        velocity_profiles (dat_PC, cas, ts_cycle);
        
        % Create Fourier flow rate data for ANSYS input - Uniform
        Q0_ansys(dat_PC, cas, 30, ts_cycle);

        % PC-MRI measurements animation u, Q, and Vs
        MRI_locations(dat_PC, cas, ts_cycle);
    end

    for i = 1:length(case_name)     
        for j = 1:length(mesh_size)
            case_i = case_name {i};
            mesh_j = mesh_size (j);

            DNS.mesh_size = mesh_j;
            DNS.case = case_i+"_dx"+formatDecimal(DNS.mesh_size); 
            
            % full ansys folder path
            DNS.ansys_path = ansys_path;
            
            DNS.TUI_path = fullfile(cas.diransys_in, DNS.case);
            
            % ansys working folder
            DNS.path_out_report = fullfile(cas.diransys_out,DNS.case);
            
            
            DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
            DNS.slices.locations = [cas.locations(1:end-1), "bottom", "FM-"+delta_h_FM, "top"]';
            DNS.cycles = cycles;
            DNS.delta_h_FM = delta_h_FM;
            DNS.iterations_ts = iterations_ts;
            DNS.ts_cycle = ts_cycle;
            DNS.subject = cas.subj;
            
            DNS_cases{i,j} = DNS.case;



            save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
            clear DNS
        end
    end
    DNS_cases = reshape(DNS_cases.', 1, []); %reshape into a single row
end