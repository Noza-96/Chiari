
function create_ansys_inputs(dat_PC, cas, ts_cycle)

    % Initialization
    loc_ID = [1, dat_PC.Ndat];
    sstt = {"top", "bottom"};
    modes = 20; % Fourier modes
    t = linspace(0, 1, ts_cycle);  % Time vector

    load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');

    for ii = 1:dat_PC.Ndat

        % Extract and scale pcMRI data
        U = -dat_PC.U_SAS{ii} * 1e-2;       % [m/s]
        xyz = dat_PC.pixel_coord{ii} * 1e-3; % [m]
        Q = -dat_PC.Q_SAS{ii};              % Flow rate

        % Trim empty rows and columns with padding
        zeroRows = all(U(:,:,1) == 0, 2);
        zeroCols = all(U(:,:,1) == 0, 1);
        band = 1;
        rows = max(find(~zeroRows, 1) - band, 1):min(find(~zeroRows, 1, 'last') + band, size(U,1));
        cols = max(find(~zeroCols, 1) - band, 1):min(find(~zeroCols, 1, 'last') + band, size(U,2));
        U = U(rows, cols, :);
        xyz = xyz(rows, cols, :);

        % Reshape to 2D
        U = reshape(U, [], size(U,3));
        xx = reshape(xyz(:,:,1), [], 1);
        yy = reshape(xyz(:,:,2), [], 1);
        zz = reshape(xyz(:,:,3), [], 1);

        % Fourier interpolation for velocity profiles
        uu = zeros(size(U,1), ts_cycle);
        for k = 1:size(U,1)
            [uu(k,:), ~, ~] = four_approx(U(k,:), modes, 0, ts_cycle);
        end

        % Define points in millimeters
        x_coords = [xx(1), xx(floor(end/2)), xx(end)] * 1e3;
        y_coords = [yy(1), yy(floor(end/2)), yy(end)] * 1e3;
        z_coords = [zz(1), zz(floor(end/2)), zz(end)] * 1e3;

        % Store output
        x{ii} = xx; y{ii} = yy; z{ii} = zz;
        u{ii} = uu;
        [q{ii}, ~, ~] = four_approx(Q, modes, 0, ts_cycle);
        SV{ii} = 0.5 * simps(t*dat_PC.T{ii}, abs(q{ii}), 2);

        % Compute normal vector
        V1 = [x_coords(2), y_coords(2), z_coords(2)] - [x_coords(1), y_coords(1), z_coords(1)];
        V2 = [x_coords(3), y_coords(3), z_coords(3)] - [x_coords(1), y_coords(1), z_coords(1)];
        nn = cross(V1, V2);
        nv{ii} = nn / norm(nn);

        %% Save cutting plane file
        plane_data = [z_coords(:), x_coords(:), y_coords(:)];
        filename = fullfile(cas.diransys_in, "planes", cas.locations{ii} + ".txt");
        write_plane_file(filename, plane_data);

        %% Top/bottom slice data
        if any(loc_ID == ii)
            idx_loc = find(loc_ID == ii);
            tag = sstt{idx_loc};

            % --- 1) Save clip plane ---
            filename = fullfile(cas.diransys_in, "planes", tag + "_plane.txt");
            write_plane_file(filename, plane_data);

            % --- 2) Save flow rate as Fourier series ---
            An = -dat_PC.fou.am{loc_ID(idx_loc)};
            T = dat_PC.T{loc_ID(idx_loc)};
            equation_terms = strings(1, modes);
            Q_recon = zeros(1, ts_cycle);
            for n = 1:modes
                omega = n * 2 * pi / T;
                real_part = real(An(n));
                imag_part = imag(An(n));
                equation_terms(n) = sprintf("+%.6f*cos(%.6f*t*1[s^-1]) - %.6f*sin(%.6f*t*1[s^-1])", ...
                                            real_part, omega, imag_part, omega);
                Q_recon = Q_recon + 2 * (real_part * cos(omega * t) - imag_part * sin(omega * t));
            end
            eq_str = sprintf("(%s)*2E-6[m^3/s]", strjoin(equation_terms, ' '));
            eq_str = regexprep(eq_str, '\+-', '- ');
            eq_str = regexprep(eq_str, '-\s*-', '+ ');
            filename = fullfile(cas.diransys_in, "flow-rates", "Q_" + tag + ".txt");
            write_text_file(filename, eq_str);

            % --- 3) Save velocity profiles ---
            filename = fullfile("Functions", "empty_inlet_vel.csv");
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
                T = cell2table(template);
                filename = fullfile(cas.diransys_in, "profiles", tag + "_prof_" + num2str(n) + ".csv");
                writetable(T, filename, 'WriteVariableNames', false);
            end

            fprintf('saved velocity profile, plane, and flow rate for %s-pcmri in ansys input folder\n', tag);
        end
    end

    % Output structure
     pcmri.x = x; %[m]
     pcmri.y = y;
     pcmri.z = z;
     pcmri.SV = SV;
     pcmri.u_normal = u; %[cm/s]
     pcmri.normal_v = nv;
     pcmri.q = q; %[ml/s]
     pcmri.locations = cas.locations;
     pcmri.locz = dat_PC.locz; %[cm]
     pcmri.Ndat = dat_PC.Ndat;
     pcmri.Nt = ts_cycle;
     pcmri.case = 'PC-MRI';
     pcmri.T = dat_PC.T;
     pcmri.FM = abs(anatomy.FM)/10; %[cm]

    save(fullfile(cas.dirmat, "pcmri_vel"), 'pcmri');
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
