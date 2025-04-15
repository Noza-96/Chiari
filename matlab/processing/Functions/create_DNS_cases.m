function DNS_cases = create_DNS_cases (case_name, mesh_size, cas, cycles, delta_h_FM, iterations_ts, ts_cycle)
    DNS_cases = cell(length(case_name),length(mesh_size));
    for i = 1:length(case_name)     
        for j = 1:length(mesh_size)
            case_i = case_name {i};
            mesh_j = mesh_size (j);
    
            DNS.mesh_size = mesh_j;
            DNS.case = case_i+"_dx"+formatDecimal(DNS.mesh_size); 
            [DNS.geom, DNS.sim] = get_type_simulation(case_i);
            
            % full ansys folder path
            DNS.ansys_path = correct_path(full_path(fullfile(pwd, '..', '..', '..','computations','ansys')));  
            DNS.TUI_path = fullfile(cas.diransys_in);       
            % ansys working folder
            DNS.path_out_report = fullfile(cas.diransys_out,DNS.case);          
            % reports at each time step 
            DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
            DNS.slices.locations = [cas.locations(1:end-1), "bottom", "top"]';
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
    disp('created DNS.mat with cases information ...')
end

%% Auxiliary functions 

function [type_geometry, type_simulation] = get_type_simulation(DNS_case)
    type_geometry = regexp(DNS_case, '^[a-zA-Z]+', 'match', 'once');
    type_simulation = str2double(regexp(DNS_case, '\d+', 'match', 'once'));
end

function filepath = correct_path(filepath)
    filepath = strrep(strrep(filepath, '\', '\\'), '/', '\\');
end