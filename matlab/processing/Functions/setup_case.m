function DNS_cases = setup_case(cas, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM, ansys_path)

DNS_cases = cell(length(case_name),length(mesh_size));

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
            DNS.slices.locations = [cas.locations(1:end-1), "bottom", "FM-25", "top"]';
            DNS.cycles = cycles;
            DNS.delta_h_FM = delta_h_FM;
            DNS.iterations_ts = iterations_ts;
            DNS.ts_cycle = ts_cycle;
            DNS.subject = cas.subj;
            
            DNS_cases{i,j} = DNS.case;

            % Check if the case file exists
            if ~isfile(fullfile(cas.diransys_in, DNS.case + "_0.cas.gz"))
                fprintf('Case file %s needs to be created ...\n', DNS.case);
            end

            save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
            clear DNS
        end
    end
    DNS_cases = reshape(DNS_cases.', 1, []); %reshape into a single row
end