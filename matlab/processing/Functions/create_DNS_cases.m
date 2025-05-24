function DNS_cases = create_DNS_cases (case_name, mesh_size, cas, cycles, iterations_ts, ts_cycle)
    DNS_cases = cell(length(case_name),length(mesh_size));
    for i = 1:length(case_name)     
        for j = 1:length(mesh_size)
            case_i = case_name {i};
            mesh_j = mesh_size (j);
    
            [DNS.geom, DNS.sim, DNS.inlet] = get_type_simulation(case_i);
            DNS.mesh_size = mesh_j;
            DNS.case = DNS.geom + string(DNS.sim) + DNS.inlet + "_dx" + formatDecimal(DNS.mesh_size);
            
            % full ansys folder path
            DNS.ansys_path = correct_path(full_path(fullfile(pwd, '..', '..', '..','computations','ansys')));
            DNS.TUI_path = fullfile(cas.diransys_in, "journals");       
            % ansys working folder
            DNS.path_out_report = fullfile(cas.diransys_out, DNS.case);          
            % reports at each time step 
            DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
            DNS.slices.locations = ["top", cas.locations(2:end-1), "bottom"]';
            DNS.cycles = cycles;
            DNS.iterations_ts = iterations_ts;
            DNS.ts_cycle = ts_cycle;
            DNS.subject = cas.subj;
            DNS_cases{i,j} = DNS.case;

            if DNS.sim == 2
                DNS.continuity = "tonsils";
            end
            save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
            clear DNS
        end     
    end
    DNS_cases = reshape(DNS_cases.', 1, []); %reshape into a single row
    disp('created DNS.mat with cases information ...')
end

%% Auxiliary functions 

function [type_geometry, type_simulation, boundary_inlet] = get_type_simulation(DNS_case)
    DNS_case = char(DNS_case);
    type_geometry = regexp(DNS_case, '^[a-zA-Z]+', 'match', 'once');
    type_simulation = str2double(regexp(DNS_case, '\d+', 'match', 'once'));
    if ismember(type_simulation, [0, 1])
        boundary_inlet = 'top'; % by default top 
        if length(DNS_case) == 3 && DNS_case(end)=='b'
            boundary_inlet = 'bottom';
        elseif length(DNS_case) == 3 && DNS_case(end)=='t'
            boundary_inlet = 'top';
        end
    else
        boundary_inlet = '';
    end
end

function filepath = correct_path(filepath)
    filepath = strrep(filepath, '\', '/');
end