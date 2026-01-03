function [cas, dat_PC, pcmri, DNS] = main_11_postprocessing(cas, cases, mesh_size, ts_cycle, cycle)

    fprintf("11) Post-processing:\n");
    
    for case_name = cases
        for msh = mesh_size
            for ts = ts_cycle
                for cyc = cycle
                    % load MRI data for subject
                    load(fullfile(cas.dir.mat, "data_3.mat"), 'cas', 'dat_PC');
                    load(fullfile(cas.dir.mat, "pcmri_vel.mat"), 'pcmri');
                
                    [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{1});
                    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(msh) + version + "_ts_" + ts + "_N_" + cyc;

                    fprintf('\n%s: ', DNS_case);
                
                    % Load DNS files
                    if ~exist(fullfile(cas.dir.mat, "DNS", "DNS_"+DNS_case+".mat"), 'file')
                        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(msh) + version;
                        if ~exist(fullfile(cas.dir.mat, "DNS", "DNS_"+DNS_case+".mat"), 'file')
                            fprintf(2,'\nFile "%s" does not exist, preprocessing needs to be done \n', "DNS_"+DNS_case+".mat");
                            return
                        end
                    end
                
                    load(fullfile(cas.dir.mat, "DNS", "DNS_"+DNS_case+".mat"), 'DNS');
                
                    output_file = fullfile(cas.dir.mat, "DNS-results", "DNS_" + DNS_case + ".mat");

                    if exist(output_file, 'file')
                            fprintf('- Data already extracted, continue to next...\n');
                            load(output_file,'DNS');
                            continue  
                    else
                        fprintf('- Reading data for the first time...\n');
                    end
            
                    % Define initial cycle number
                    N0 = (cyc - 1) * ts;
                    Nloc = length(DNS.slices.locations);
                    index = cell(1, Nloc); 
                    x_DNS = cell(Nloc, 1); 
                    y_DNS = cell(Nloc, 1); 
                    z_DNS = cell(Nloc, 1); 
                    normal_v = cell(1,pcmri.Ndat);
                    u_DNS = cell(Nloc, ts); 
                    un_DNS = cell(Nloc, ts ); 
                    v_DNS = cell(Nloc, ts ); 
                    w_DNS = cell(Nloc, ts ); 
                    p_DNS = cell(Nloc, ts ); 
                    u_combined = cell(Nloc, 1); 
                    un_combined = cell(Nloc, 1); 
                    v_combined = cell(Nloc, 1); 
                    w_combined = cell(Nloc, 1); 
                    p_combined = cell(Nloc, 1); 
                    slice_z = zeros(Nloc, 1);
                    Dz = DNS.Dz;
                
                    % Calculate mean z-location slices
                    for i = 1:pcmri.Ndat
                        slice_z(i) = mean(pcmri.z{i}(:));
                    end
                
                    % Load data for each time step
                    for n = 1:ts
                        N = N0 + n;
                        
                        % Define file path for velocity data
                        filePath = fullfile(cas.dir.ansys_out, DNS.case, DNS.case + "_report-" + sprintf('%04d', N));
        
                        if ~exist(filePath, 'file')
                            fprintf(2,'- File "%s" does not exist, simulation needs to be done\n', filePath);
                            return
                        end
                        
                        % Read data from file
                        data = read_ansys_data(filePath);
                        
                        % Initialize X, Y, Z coordinates during first iteration
                        if n == 1
                            X = data{2}; % [m]
                            Y = data{3}; % [m]
                            Z = data{4}; % [m]
                            DNS.slices.locz = slice_z; % Convert to m
                        end
                
                
                        % Velocity components
                        [W, V, U, P] = deal(data{5}, data{6}, data{7}, data{8});
                
                        if startsWith(DNS.geom, 'b')
                            fileID = fopen(fullfile(DNS.path_out_report,'..', "area-z"), 'r');
                            data = textscan(fileID, '%s %f', 'HeaderLines', 4);
                            DNS.out.area = data{2};
                        else
                            % Loop through DNS locations and store data
                            for k = 1:length(DNS.slices.locz)
                                if n == 1
                                    % Find indices where Z is within range of current location
                                    index{k} = find(abs(Z - DNS.slices.locz(k)) <= 0.2*1e-2); 
                                    x_DNS{k} = X(index{k});
                                    y_DNS{k} = Y(index{k});
                                    z_DNS{k} = Z(index{k});
                                end
                    
                                % Assign specific points to x_coords, y_coords, and z_coords
                                x_coords = [x_DNS{k}(1), x_DNS{k}(floor(end/2)), x_DNS{k}(end)];
                                y_coords = [y_DNS{k}(1), y_DNS{k}(floor(end/2)), y_DNS{k}(end)];
                                z_coords = [z_DNS{k}(1), z_DNS{k}(floor(end/2)), z_DNS{k}(end)];
                                
                                % Define points on the plane
                                P1 = [x_coords(1), y_coords(1), z_coords(1)];
                                P2 = [x_coords(2), y_coords(2), z_coords(2)];
                                P3 = [x_coords(3), y_coords(3), z_coords(3)];
                                
                                % Calculate vectors and normal
                                V1 = P2 - P1;
                                V2 = P3 - P1;
                                
                                nn = cross(V1, V2);
                                nn = nn / norm(nn); % Normalize
                                
                                % Ensure the z-component of the normal vector is positive
                                if nn(3) < 0
                                    nn = -nn; % Flip the normal vector
                                end
                                normal_v{k} = nn;        
                                % Store velocity and pressure for current time step
                                u_DNS{k, n} = U(index{k});
                                v_DNS{k, n} = V(index{k});
                                w_DNS{k, n} = W(index{k});
                                p_DNS{k, n} = P(index{k});
                    
                                % Extract velocity components for the current indices
                                u_vel = u_DNS{k, n}; % x-component
                                v_vel = v_DNS{k, n}; % y-component
                                w_vel = w_DNS{k, n}; % z-component
                                
                                % Combine velocity components into a single velocity vector
                                velocity_vector = [u_vel(:), v_vel(:), w_vel(:)];
                                
                                % Calculate normal velocity component for each point
                                un_DNS{k, n} = velocity_vector * (normal_v{k})'; % Dot product
                            end
                        end
                    end
            
                    % Combine data across time steps for each location
                    for k = 1:length(DNS.slices.locz)
                        u_combined{k} = cell2mat(u_DNS(k, :));
                        v_combined{k} = cell2mat(v_DNS(k, :));
                        w_combined{k} = cell2mat(w_DNS(k, :));
                        p_combined{k} = cell2mat(p_DNS(k, :));
                        un_combined{k} = cell2mat(un_DNS(k, :));
                    end
                
                    % Store combined data in DNS structure
                    DNS.slices.x = x_DNS;
                    DNS.slices.y = y_DNS;
                    DNS.slices.z = z_DNS;
                    DNS.slices.u = u_combined;
                    DNS.slices.v = v_combined;
                    DNS.slices.w = w_combined;
                    DNS.slices.p = p_combined;
                    DNS.slices.normal_v = normal_v;
                    DNS.slices.u_normal = un_combined;
                    DNS.slices.case = DNS_case;
                    
                    save(fullfile(cas.dir.mat, "DNS_"+DNS_case+".mat"), 'DNS');  
                
                    % load output report
        
                    filePath = full_path(correct_path(fullfile(pwd, DNS.path_out_report, '..', DNS.case, DNS.case + "_report.out"))); 
        
                    if exist(filePath, 'file') == 2 % 'file' ensures it checks for files only
                
                        index_0 = 7; % #entries before dp-Dz
                        % Open and read the file
                        fileID = fopen(filePath, 'r');
                        %time-step, %t, %u_max, %q (bottom, top, tonsils), %dp (5, 10, 50)
                        formatSpec = ['%d', repmat(' %f', 1, index_0 - 1 + length(Dz))];  % 1 integer + N floats
                        data = textscan(fileID, formatSpec, 'HeaderLines', 4);
                        fclose(fileID);
                    
                        % Assign the columns to variables
                        DNS.out.ts = data{1};        % First column - Time Step
                        DNS.out.t = data{2};         % Second column - flow-time
                        DNS.out.u_max = data{3};     % Third column - dp
                
                        DNS.out.q_bottom = data{4};  % Fourth column - q_bottom
                        DNS.out.q_top = data{5};  
        
                        for ii = 1:length(Dz)
                            DNS.out.dp.val{ii} = data{index_0}; 
                            DNS.out.dp.loc{ii} = "fm-"+Dz(ii);
                            index_0 = index_0 + 1;
                        end
                
                        if ~startsWith(DNS.geom, 'b')
                            fprintf('compute RMSE error ...\n');
                            [DNS.RMSE,DNS.RMSE_ave, DNS.RMSE_space, DNS.out.q] = compute_RMSE(DNS, pcmri, [dat_PC.dx,dat_PC.dy]/1000);
                        end
                        save(output_file, 'DNS');
                    else
                        % File does not exist, provide a warning or handle as needed
                        warning("File %s_report.out does not exist. DNS structure not updated.", DNS_case);
                    end
                end
                fprintf('Done!\n');
            end
        end
    end
end

function data = read_ansys_data(filePath)
    % Read data from ANSYS report file
    fileID = fopen(filePath, 'r');
    data = textscan(fileID, '%d %f %f %f %f %f %f %f', 'HeaderLines', 1);
    fclose(fileID);
end

function [RMSE, RMSE_ave, RMSE_space, q, u_int] = compute_RMSE(DNS, pcmri, pixel_size)
    dx = pixel_size(1); dy = pixel_size(2);
    pcmri = apply_roi_pcmri(pcmri);
    Nt = DNS.ts_cycle;

    RMSE = cell(1, pcmri.Ndat);           % RMSE(t) per location
    RMSE_ave = cell(1, pcmri.Ndat);       % time-averaged RMSE (per pixel, then spatial average)
    q = cell(1, pcmri.Ndat); % RMSE over space, then time average
    u_int = cell(1, pcmri.Ndat);

    for iloc = 1:pcmri.Ndat
        % PCMRI data at this location
        Xp = pcmri.x{iloc};
        Yp = pcmri.y{iloc};
        up = pcmri.u_normal{iloc};    % [Npts_p × Nt]

        % DNS data at this location
        Xd = DNS.slices.x{iloc};
        Yd = DNS.slices.y{iloc};
        ud = DNS.slices.u_normal{iloc};  % [Npts_d × Nt]

        rmse_vec = zeros(1, pcmri.Nt);    % RMSE(t)
        zero_error = 1;

        % Skip location if boundary error should be zero
        if ( ...
            (iloc == 1 && (DNS.sim == 2 || DNS.sim == 3 ||(ismember(DNS.sim, 1) && strcmp(DNS.inlet, 'top')))) || ...
            (iloc == pcmri.Ndat && (DNS.sim == 2 || DNS.sim == 3 || (ismember(DNS.sim, 1) && strcmp(DNS.inlet, 'bottom')))) ...
           )
            fprintf('    %s: zero error\n', pcmri.locations{iloc}); 
            zero_error = 0;
        end

        
        
        for it = 1:DNS.ts_cycle
            u_avg = NaN(size(Xp));  % preallocate
            for i = 1:length(Xp)
                % Find DNS points inside square of side dx × dy centered at (Xp(i), Yp(i))
                in_square = abs(Xd - Xp(i)) <= dx/2 & abs(Yd - Yp(i)) <= dy/2;
                if any(in_square)
                    u_avg(i) = mean(ud(in_square, it), 'omitnan');
                end
            end

            F = scatteredInterpolant(Xd, Yd, ud(:, it), "natural", 'none'); 
            u_int_loc_full = F(Xp, Yp);   

            if it == 1
                valid = ~isnan(u_avg) & ~isnan(u_int_loc_full);
                Nv = sum(valid);
                n_invalid = sum(~valid);
                u_int_loc = NaN(Nv, Nt);
            end
        
            if it == 1 && zero_error
                fprintf('    %s: exclude %d PCMRI points that fall outside the DNS averaging domain\n', ...
                        pcmri.locations{iloc}, n_invalid);
            end
        
            diff = u_avg(valid) - up(valid, it);
            rmse_vec(it) = sqrt(mean(diff.^2));
            u_int_loc(:,it)       = u_int_loc_full(valid);
        end
        % Compute RMSE over space (for each t), then average over t

    
        % Preallocate error matrix
        sq_err_all = zeros(Nv, Nt);
        u_ave_time = zeros(Nv, Nt);
    
        % Recompute interpolated values at all time points and fill matrix
        for it = 1:Nt

            % ---- 1) local pixel-average at PC-MRI resulution----
            u_avg = NaN(size(Xp));
            for i = 1:length(Xp)
                in_square = abs(Xd - Xp(i)) <= dx/2 & abs(Yd - Yp(i)) <= dy/2;
                if any(in_square)
                    u_avg(i) = mean(ud(in_square, it), 'omitnan');
                end
            end

            diff_t = u_avg(valid) - up(valid, it);
            sq_err_all(:, it) = diff_t.^2;
            u_ave_time(:, it) = u_avg(valid);
        end

        % Compute RMSE(t)
        RMSE{iloc} = rmse_vec*zero_error;
        RMSE_ave{iloc} = mean(rmse_vec)*zero_error;
    
        % Compute RMSE at each point (averaged over time)
        rmse_pts = sqrt(mean(sq_err_all, 2));  % [Nv × 1]
    
        % Store results
        RMSE_space.val{iloc} = rmse_pts*zero_error;  % RMSE per point
        RMSE_space.x{iloc} = Xp(valid);
        RMSE_space.y{iloc} = Yp(valid);
        RMSE_space.u_normal{iloc} = u_ave_time;  
        q{iloc} = sum(u_ave_time*(dx*dy)*1e6,1);  
        RMSE_space.u_int{iloc} = u_int_loc;
    end
end