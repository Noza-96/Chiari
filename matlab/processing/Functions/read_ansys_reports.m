function read_ansys_reports(cas, dat_PC,DNS_case)
    % Load DNS files
    load(fullfile(cas.dirmat, "DNS_"+DNS_case+".mat"), 'DNS');
    
    % Define initial cycle number
    N0 = (DNS.cycles - 1) * DNS.ts_cycle;
    Nloc = length(DNS.slices.locations);
    
    % Preallocate arrays for data storage
    index = cell(1, Nloc); 
    x_DNS = cell(Nloc, 1); 
    y_DNS = cell(Nloc, 1); 
    z_DNS = cell(Nloc, 1); 
    normal_v = cell(1,dat_PC.Ndat);
    u_DNS = cell(Nloc, 100); 
    un_DNS = cell(Nloc, 100); 
    v_DNS = cell(Nloc, 100); 
    w_DNS = cell(Nloc, 100); 
    p_DNS = cell(Nloc, 100); 
    u_combined = cell(Nloc, 1); 
    un_combined = cell(Nloc, 1); 
    v_combined = cell(Nloc, 1); 
    w_combined = cell(Nloc, 1); 
    p_combined = cell(Nloc, 1); 
    slice_z = zeros(Nloc, 1);

    % Calculate mean z-location slices
    for i = 1:length(dat_PC.pixel_coord)
        slice_z(i) = mean(mean(dat_PC.pixel_coord{i}(:,:,3)));
    end

    slice_z(end-1) = slice_z(1) - DNS.delta_h_FM;

    % Load data for each time step
    for n = 1:DNS.ts_cycle
        N = N0 + n;
        
        % Define file path for velocity data
        filePath = fullfile(cas.diransys_out, DNS.case, DNS.case + "_report-" + sprintf('%04d', N)); 
        if ~exist(filePath, 'file')
            error('File "%s" does not exist.', filePath);
        end
        
        % Read data from file
        data = read_ansys_data(filePath);
        
        % Initialize X, Y, Z coordinates during first iteration
        if n == 1
            X = data{2}; % [m]
            Y = data{3}; % [m]
            Z = data{4}; % [m]
            slice_z(end) = max(Z(:)) * 1e3; % top slice
            DNS.slices.locz = slice_z / 1e3; % Convert to m
        end


        % Velocity components
        [U, V, W, P] = deal(data{7}, data{6}, data{5}, data{8});
        
        % Loop through DNS locations and store data
        for k = 1:length(DNS.slices.locz)
            if n == 1
                % Find indices where Z is within range of current location
                index{k} = find(abs(Z - DNS.slices.locz(k)) <= 0.2*1e-2); 
                
                % Store coordinates for current location
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
            
            % Normal vector and normalization
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
    % Save updated DNS structure
    save(fullfile(cas.dirmat, "DNS_"+DNS_case+".mat"), 'DNS');

%% load output report
% Check if the file exists
if exist(DNS.path_out_report, 'file') == 2 % 'file' ensures it checks for files only
    % Open and read the file
    fileID = fopen(DNS.path_out_report, 'r');
    data = textscan(fileID, '%d %f %f %f %f %f %f', 'HeaderLines', 4);
    fclose(fileID);

    % Assign the columns to variables
    DNS.out.ts = data{1};        % First column - Time Step
    DNS.out.t = data{2};         % Second column - flow-time
    DNS.out.dp = data{3};        % Third column - dp
    DNS.out.q_bottom = data{4};  % Fourth column - q_bottom
    DNS.out.q_top = data{5};  
    DNS.out.q_cord = data{6}; 
    DNS.out.u_max = data{7};  
    
    % Save updated DNS structure
    save(fullfile(cas.dirmat, "DNS_" + DNS_case + ".mat"), 'DNS');
else
    % File does not exist, provide a warning or handle as needed
    warning("File %s_variables.out does not exist. DNS structure not updated.", DNS_case);
end

end

function data = read_ansys_data(filePath)
    % Read data from ANSYS report file
    fileID = fopen(filePath, 'r');
    data = textscan(fileID, '%d %f %f %f %f %f %f %f', 'HeaderLines', 1);
    fclose(fileID);
end
