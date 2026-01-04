function [cas, dat_PC, pcmri, DNS] = main_11_postprocessing(cas, cases, mesh_size, ts_cycle, cycle)

    fprintf("11) Post-processing:\n");

    freq_lim = [1,8]; %Hz to calculate longitudinal impedance
    
    for case_name = cases
        for msh = mesh_size
            for ts = ts_cycle
                for cyc = cycle
                    % load MRI data for subject
                    load(fullfile(cas.dir.mat, "data_3.mat"), 'cas', 'dat_PC');
                    load(fullfile(cas.dir.mat, "pcmri_vel.mat"), 'pcmri');
                    [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{1});
                    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(msh) + version + "_ts_" + ts + "_N_" + cyc;
                    fprintf('\n%s:\n', DNS_case);
                
                    % Load DNS files
                    if ~exist(fullfile(cas.dir.mat, "DNS", "DNS_" + DNS_case + ".mat"), 'file')
                        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(msh) + version;
                        if ~exist(fullfile(cas.dir.mat, "DNS", "DNS_" + DNS_case + ".mat"), 'file')
                            fprintf(2,'\n- File "%s" does not exist, preprocessing needs to be done \n', "DNS_"+DNS_case+".mat");
                            return
                        end
                    end
                
                    load(fullfile(cas.dir.mat, "DNS", "DNS_" + DNS_case + ".mat"), 'DNS');
                    output_file = fullfile(cas.dir.mat, "DNS-results", "DNS_" + DNS_case + ".mat");

                    if exist(output_file, 'file')
                        fprintf('- Data already extracted, continue to next...\n');
                        load(output_file,'DNS');
                        continue  
                    else
                        fprintf('- Reading data for the first time...\n');
                    end
            
                    % Define initial cycle number
                    N0 = (cyc - 1) * ts; Nloc = length(DNS.slices.locations);
                    index = cell(1, Nloc); x_DNS = cell(Nloc, 1); y_DNS = cell(Nloc, 1); z_DNS = cell(Nloc, 1); 
                    normal_v = cell(1,pcmri.Ndat); u_DNS = cell(Nloc, ts); un_DNS = cell(Nloc, ts ); 
                    v_DNS = cell(Nloc, ts );  w_DNS = cell(Nloc, ts ); p_DNS = cell(Nloc, ts ); 
                    u_combined = cell(Nloc, 1); un_combined = cell(Nloc, 1); v_combined = cell(Nloc, 1); 
                    w_combined = cell(Nloc, 1); p_combined = cell(Nloc, 1); slice_z = zeros(Nloc, 1); Dz = DNS.Dz;
                
                    % Calculate mean z-location slices
                    slice_z = cellfun(@(x) mean(x(:)), pcmri.z);
                
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
                            DNS.slices.locz = slice_z;
                        end
                
                        % Velocity components
                        [W, V, U, P] = deal(data{5}, data{6}, data{7}, data{8});
                
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
                    filePath = fullfile(cas.dir.ansys_out, DNS.case, DNS.case + "_report.out"); 
        
                    if exist(filePath, 'file') == 2 
                
                        index_0 = 7; % #entries before dp-Dz
                        fileID = fopen(filePath, 'r');
                        %time-step, %t, %u_max, %q (bottom, top, tonsils), dp (#Dz)
                        formatSpec = ['%d', repmat(' %f', 1, index_0 - 1 + length(Dz))];
                        data = textscan(fileID, formatSpec, 'HeaderLines', 4);
                        fclose(fileID);
                    
                        % Assign the columns to variables
                        DNS.out.ts = data{1};        % Time Step
                        DNS.out.t = data{2};         % flow-time
                        DNS.out.u_max = data{3};     % u_max
                        DNS.out.q_bottom = data{4};  % q_bottom
                        DNS.out.q_top = data{5};     % q_top
                        DNS.out.q_tonsils = data{6}; % q_top
                        for ii = 1:length(Dz)
                            DNS.out.dp.val{ii} = data{index_0}; 
                            DNS.out.dp.loc{ii} = "fm-"+Dz(ii);
                            index_0 = index_0 + 1;
                        end
                        % find location z=0 and z=-25mm to calculate LI
                        loc = DNS.out.dp.loc;
                        val = DNS.out.dp.val;
                        
                        % Convert loc to string array
                        loc_str = string(cellfun(@(x) x{1}, loc, 'UniformOutput', false));
                        
                        % Indices you want
                        i_fm0   = loc_str == "fm-0";
                        i_fm25  = loc_str == "fm--25";
                        
                        % Corresponding values
                        dp_LI = val{i_fm0}-val{i_fm25};

                        [DNS.out.LI.ZL, DNS.out.LI.ILI] = longitudinal_impedance(dp_LI, DNS.out.q_bottom, dat_PC.T{end}, freq_lim);
                        fprintf('- Compute RMSE error...\n');
                        [DNS.RMSE.time, DNS.RMSE.space, DNS.RMSE.ave] = compute_RMSE(DNS, pcmri, [dat_PC.fcal_H_cm_px{1},dat_PC.fcal_V_cm_px{1}]/100);
                        fprintf('- Saved .mat file...\n');
                        save(output_file, 'DNS');
                    else
                        warning("- File %s_report.out does not exist. DNS structure not updated.", DNS_case);
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

function [RMSE_time, RMSE_space, RMSE_ave] = compute_RMSE(DNS, pcmri, pixel_size)
    dx = pixel_size(1); dy = pixel_size(2);
    pcmri = apply_roi_pcmri(pcmri);
    Nt = DNS.ts_cycle;
    RMSE_time = cell(1, pcmri.Ndat);           % RMSE(t) per location
    RMSE_ave = cell(1, pcmri.Ndat);       % time-averaged RMSE (per pixel, then spatial average)

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
        if ((iloc == 1 && (DNS.sim == 2 || DNS.sim == 3 ||(ismember(DNS.sim, 1) && strcmp(DNS.inlet, 'top')))) || ...
            (iloc == pcmri.Ndat && (DNS.sim == 2 || DNS.sim == 3 || (ismember(DNS.sim, 1) && strcmp(DNS.inlet, 'bottom')))))
            fprintf('    %s: zero error\n', pcmri.locations{iloc}); 
            zero_error = 0;
        end
        
        for it = 1:DNS.ts_cycle
            % average CFD velocity over pixel bin
            u_avg = NaN(size(Xp)); 
            for i = 1:length(Xp)
                % Find DNS points inside square of side dx × dy centered at (Xp(i), Yp(i))
                in_square = abs(Xd - Xp(i)) <= dx/2 & abs(Yd - Yp(i)) <= dy/2;
                if any(in_square)
                    u_avg(i) = mean(ud(in_square, it), 'omitnan');
                end
            end

            if it == 1
                valid = ~isnan(u_avg);
                Nv = sum(valid);
                n_invalid = sum(~valid);
            end
        
            if it == 1 && zero_error
                fprintf('    %s: exclude %d PCMRI points that fall outside the DNS averaging domain\n', ...
                        pcmri.locations{iloc}, n_invalid);
            end
        
            diff = u_avg(valid) - up(valid, it);
            rmse_vec(it) = sqrt(mean(diff.^2));
        end

        % Compute RMSE over space (for each t), then average over t
        sq_err_all = zeros(Nv, Nt);
        u_ave_time = zeros(Nv, Nt);
    
        % Recompute interpolated values at all time points and fill matrix
        for it = 1:Nt
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
        RMSE_time{iloc} = rmse_vec*zero_error;
        RMSE_ave{iloc} = mean(rmse_vec)*zero_error;
    
        % Compute RMSE at each point (averaged over time)
        rmse_pts = sqrt(mean(sq_err_all, 2));  % [Nv × 1]
    
        % Store results
        RMSE_space.val{iloc} = rmse_pts*zero_error;  % RMSE per point
        RMSE_space.x{iloc} = Xp(valid);
        RMSE_space.y{iloc} = Yp(valid);
        RMSE_space.u_normal{iloc} = u_ave_time;  
        
    end
end

function [ZL,LI] = longitudinal_impedance(dp, q, T, freq_lim)
    % Calculate longitudinal impedance
    % Inputs:
    %   cas     - Case information including directory paths
    %   dat_PC  - Data from pressure cycle
    %   DNS     - Simulation results containing pressure and flow data
    
    N_modes = 10;
    f = (1:N_modes)/T;
    % Restrict to 1–8 Hz
    f_min = freq_lim(1); 
    f_max = freq_lim(2);


    % Fourier analysis
    [~, ~, Qm, ~] = four_approx(q * 1e6, N_modes, 0, 100); % Flow rate in [ml/s]
    [~, ~, Pm, ~] = four_approx(dp * 10, N_modes, 0, 100); % Pressure jump in [dyn/cm^2]
    
    % Calculate longitudinal impedance
    ZL = abs(Pm ./ Qm)'; % Impedance [dyn-s/cm^5]

    % Interpolate ZL at the exact endpoints
    ZL_min = interp1(f, ZL, f_min, 'linear', 'extrap');
    ZL_max = interp1(f, ZL, f_max, 'linear', 'extrap');



    % Augment arrays with the clipped endpoints
    f_clip = [f_min, f(f>=f_min & f<=f_max), f_max];
    ZL_clip = [ZL_min, ZL(f>=f_min & f<=f_max), ZL_max];
    
    % Piecewise-linear integral = trapezoidal rule
    LI = trapz(f_clip, ZL_clip);
end
