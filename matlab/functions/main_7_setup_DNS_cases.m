function [cas, dat_PC, DNS_cases] = main_7_setup_DNS_cases(cas, case_name, mesh_size, ts_cycle, cycles, iterations_ts, z_p)
% Instructions for case_name:
% c: geometry boundded by 2, caudal and rostral extreme, MRI planes. 
% c0 for zero pressure top and bottom flow rate (uniform velocity)
% c1 for zero pressure top and bottom spatially resolved velocity
% c2 for two inlet velocities; continuity: normal velocity tonsils 
% c3 for two inlet velocities; continuity: multiple regions
% if ligaments or nerve roots, add l/n after c
% if different versions of geometries, add _v# at the end
% e.g. cl3_v1 does simulation type 3, with geometry containing ligaments and 
% version #v1 (there might be different versions of ligaments)

    fprintf("7) Setup DNS cases:\n")  
    [cas, dat_PC, repeat_initialization] = check_subject_initialization (cas, ts_cycle, 0);
    
    if repeat_initialization
        fprintf('- Ansys inputs need to be created\\updated, creating files...\n')
        create_ansys_inputs(dat_PC, cas, ts_cycle);
    else 
        fprintf('- Ansys inputs are up to date.\n')
    end
    
    DNS_cases = create_DNS_cases (cas, case_name, mesh_size, cycles, iterations_ts, ts_cycle, z_p);

end


%% Auxiliary functions 

function [cas, dat_PC, repeat_initialization] = check_subject_initialization(cas, ts_cycle, repeat_initialization)
    if nargin < 3
        repeat_initialization = 0;
    end

    % load data
    mri_data_path = fullfile(cas.dir.mat, "data_3.mat");
    load(mri_data_path, 'cas', 'dat_PC');
    
    % auxiliary file used to see if ANSYS data is up to date
    file_1 = fullfile(cas.dir.ansys_in, "flow-rates", "Q_bottom.txt");
    folder_2 = fullfile(cas.dir.ansys_in, "profiles", "ts_"+ts_cycle); 

    % Create ansys inputs if needed or if forced by repeat_initialization
    d1 = dir(mri_data_path);
    d2 = dir(file_1);

    repeat_initialization = repeat_initialization || exist(file_1, 'file') == 0 || exist(folder_2, 'dir') == 0 || ...
                            datetime(d1.datenum, 'ConvertFrom', 'datenum') > datetime(d2.datenum, 'ConvertFrom', 'datenum');
end

%%

function create_ansys_inputs(dat_PC, cas, ts_cycle)

loc_ID = [1, dat_PC.Ndat];
    sstt = {"top", "bottom"};
    modes = dat_PC.SAS.fou.M; % 
    % use period of most caudal measurement
    T = dat_PC.T{end}; 

    for ii = 1:dat_PC.Ndat

        % Extract and scale pcMRI data
        ROI = dat_PC.SAS.ROI{ii};            % [100 x 100]
        U = dat_PC.SAS.U{ii} * 1e-2;         % [m/s]
        xyz = dat_PC.pixel_coord{ii} * 1e-3; % [m]
        Q = dat_PC.SAS.Q{ii};                % Flow rate [ml/s]

        % Trim empty rows and columns with padding
        zeroRows = all(U(:,:,1) == 0, 2);
        zeroCols = all(U(:,:,1) == 0, 1);
        band = 1;
        rows = max(find(~zeroRows, 1) - band, 1):min(find(~zeroRows, 1, 'last') + band, size(U,1));
        cols = max(find(~zeroCols, 1) - band, 1):min(find(~zeroCols, 1, 'last') + band, size(U,2));
        U = U(rows, cols, :);
        xyz = xyz(rows, cols, :);
        ROI = ROI(rows, cols); 
        ROI = ROI(:);

        % Reshape to 2D
        U  = reshape(U, [], size(U, 3));
        xx = reshape(xyz(:,:,1), [], 1);
        yy = reshape(xyz(:,:,2), [], 1);
        zz = reshape(xyz(:,:,3), [], 1);

        % Fourier interpolation for velocity profiles
        uu = zeros(size(U,1), ts_cycle);
        for k = 1:size(U,1)
            [uu(k,:), ~, ~] = four_approx(U(k,:), modes, 0, ts_cycle);
        end

        % Store output
        x{ii} = xx; y{ii} = yy; z{ii} = zz;
        u{ii} = uu; roi{ii} = ROI;
        [q{ii}, ~, ~, ~] = four_approx(Q, modes, 0, ts_cycle);
        Vs{ii} = dat_PC.SAS.Vs(ii);

        % Define points in millimeters
        x_coords = [xx(1), xx(floor(end/2)), xx(end)] * 1e3;
        y_coords = [yy(1), yy(floor(end/2)), yy(end)] * 1e3;
        z_coords = [zz(1), zz(floor(end/2)), zz(end)] * 1e3;

        % Compute normal vector
        V1 = [x_coords(2), y_coords(2), z_coords(2)] - [x_coords(1), y_coords(1), z_coords(1)];
        V2 = [x_coords(3), y_coords(3), z_coords(3)] - [x_coords(1), y_coords(1), z_coords(1)];
        nn = cross(V1, V2);
        nv{ii} = nn / norm(nn);

        %% Save cutting plane file
        plane_data = [z_coords(:), x_coords(:), y_coords(:)];
        filename = fullfile(cas.dir.ansys_in, "planes", cas.locations{ii} + ".txt");
        write_plane_file(filename, plane_data);

        %% Top/bottom slice data
        if any(loc_ID == ii)
            idx_loc = find(loc_ID == ii);
            tag = sstt{idx_loc};

            % --- 1) Save clip plane ---
            filename = fullfile(cas.dir.ansys_in, "planes", tag + "_plane.txt");
            write_plane_file(filename, plane_data);

            % --- 2) Save flow rate as Fourier series ---
            An = dat_PC.SAS.fou.am{loc_ID(idx_loc)};
            equation_terms = strings(1, modes);

            for n = 1:modes
                dt = T/ts_cycle;
                omega = n * 2 * pi / T;
                real_part = real(An(n));
                imag_part = imag(An(n));
                equation_terms(n+1) = sprintf( ...
                        "+%.10f*cos(%.10f*(t-%.10f*1[s])*1[s^-1]) - %.10f*sin(%.10f*(t-%.10f*1[s])*1[s^-1])", ...
                        real_part, omega, dt, imag_part, omega, dt);
            end
            eq_str = sprintf("(%s)*2E-6[m^3/s]", strjoin(equation_terms, ' '));
            eq_str = regexprep(eq_str, '\+-', '- ');
            eq_str = regexprep(eq_str, '-\s*-', '+ ');
            filename = fullfile(cas.dir.ansys_in, "flow-rates", "Q_" + tag + ".txt");
            write_text_file(filename, eq_str);


            % --- 3) Save velocity profiles ---
            filename = fullfile("functions", "others", "empty_inlet_vel.csv");
            template = readcell(filename);
            row_offset = 10;
            n_points = length(xx);
            template(row_offset + (1:n_points), 1) = num2cell(xx);
            template(row_offset + (1:n_points), 2) = num2cell(yy);
            template(row_offset + (1:n_points), 3) = num2cell(zz);
            template(8, 1) = {tag + "_vel"};

            vel_sign = strcmp(tag, "top") * -1 + strcmp(tag, "bottom") * 1;
            for n = 1:ts_cycle
                template(row_offset + (1:n_points), 4) = num2cell(vel_sign * uu(:,n));
                tt = cell2table(template);             
                filename = fullfile(cas.dir.ansys_in, "profiles", "ts_" + ts_cycle, tag + "_prof_" + num2str(n) + ".csv");
                folderpath = fileparts(filename);
                if ~exist(folderpath, 'dir')
                    mkdir(folderpath);
                end
                writetable(tt, filename, 'WriteVariableNames', false);
            end

            fprintf('- Saved velocity profile, plane, and flow rate for %s location in ansys input folder... \n', tag);
        else
            % --- 2) Save flow rate as Fourier series in middle planes ---
            An = dat_PC.SAS.fou.am{ii};
            
            % Normalize to period of bottom measurement, to be used in simulations
            equation_terms = strings(1, modes); 
            
            for n = 1:modes
                omega = n * 2 * pi / T;
                real_part = real(An(n));
                imag_part = imag(An(n));
                equation_terms(n) = sprintf( ...
                        "+%.10f*cos(%.10f*(t-%.10f*1[s])*1[s^-1]) - %.10f*sin(%.10f*(t-%.10f*1[s])*1[s^-1])", ...
                        real_part, omega, dt, imag_part, omega, dt);
            end
            eq_str = sprintf("(%s)*2E-6[m^3/s]", strjoin(equation_terms, ' '));
            eq_str = regexprep(eq_str, '\+-', '- ');
            eq_str = regexprep(eq_str, '-\s*-', '+ ');
            filename = fullfile(cas.dir.ansys_in, "flow-rates", "Q_" + num2str(ii - 1) + ".txt");
            write_text_file(filename, eq_str);         
        end

    end

    % Output structure
     pcmri.x = x;        %[m]
     pcmri.y = y;
     pcmri.z = z;
     pcmri.roi = roi;
     pcmri.Vs = Vs;
     pcmri.u_normal = u; %[cm/s]
     pcmri.normal_v = nv;
     pcmri.q = q;        %[ml/s]
     pcmri.locations = cas.locations;
     pcmri.locz = dat_PC.locz; %[cm]
     pcmri.Ndat = dat_PC.Ndat;
     pcmri.Nt = ts_cycle;
     pcmri.case = 'PC-MRI';
     pcmri.T = dat_PC.T;

    save(fullfile(cas.dir.mat, "pcmri_vel"), 'pcmri');
end

%% Helper functions
function write_plane_file(filename, data)
    fileID = fopen(filename, 'w');
    fprintf(fileID, '3d=True\npolyline=False\n\n');
    fprintf(fileID, '%f %f %f\n', data.');
    fclose(fileID);
end

function write_text_file(filename, str)
    fileID = fopen(filename, 'wt');
    fprintf(fileID, '%s', str);
    fclose(fileID);
end

%% 


function [DNS_cases] = create_DNS_cases (cas, case_name, mesh_size, cycles, iterations_ts, ts_cycle, z_p)

    DNS_cases = cell(length(case_name),length(mesh_size));

    for i = 1:length(case_name)     
        for j = 1:length(mesh_size)
            case_i = case_name {i};
            mesh_j = mesh_size (j);
    
            DNS.subject = cas.subj; 
            [DNS.geom, DNS.sim, DNS.inlet, DNS.version] = get_type_simulation(case_i);
            DNS.case = DNS.geom + string(DNS.sim) + DNS.inlet + "_dx" + formatDecimal(mesh_j) + DNS.version + "_ts_" + ts_cycle + "_N_" + cycles;
            DNS.mesh_size = mesh_j;
            DNS.ts_cycle = ts_cycle;
            DNS.cycles = cycles;
            DNS.iterations_ts = iterations_ts;
            DNS.ansys_path = correct_path(full_path(cas.dir.ansys));
            DNS.TUI_path = fullfile(cas.dir.ansys_in, "journals");       
            DNS.path_out_report = fullfile(cas.dir.ansys_out, DNS.case); 
            if DNS.sim == 2
                DNS.continuity = "tonsils";
            end

            % reports at each time step 
            DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
            DNS.Dz = z_p; 
            DNS.slices.locations = ["top", cas.locations(2:end-1), "bottom"]';

            DNS_cases{i,j} = DNS.case;


            save(fullfile(cas.dir.mat, "DNS", "DNS_"+DNS.case+".mat"),'DNS')
            clear DNS
        end     
    end
    DNS_cases = reshape(DNS_cases.', 1, []); 
    fprintf('- DNS.mat with cases information has been created.\n\n')
end




