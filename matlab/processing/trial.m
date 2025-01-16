
    N0 = (DNS.cycles-1) * DNS.ts_cycle;
    tt = linspace(0, 1, DNS.ts_cycle);
    
    % animation settings
    azimuth = [-45, 0];
    elevation = [10, 5];
    opacity_val = 0.2;
    fs = 10; % fontsize
    sc = 5; % Scale factor for velocity vectors

    % Load mesh data
    meshID = fopen(fullfile(cas.diransys_out,"surface_mesh"), 'r');
    Mesh = textscan(meshID, '%d %f %f %f', 'HeaderLines', 3);
    X_mesh = Mesh{2} * 100;
    Y_mesh = Mesh{3} * 100;
    Z_mesh = Mesh{4} * 100;
    fclose(meshID);

    Nloc = length(DNS.locations); % add top + FM-25
    
    % Initialize the indices and data storage arrays
    index = cell(1, Nloc); % Preallocate for index lookup
    x_DNS = cell(Nloc, 1); % X-coordinates for DNS locations
    y_DNS = cell(Nloc, 1); % Y-coordinates for DNS locations
    z_DNS = cell(Nloc, 1); % Z-coordinates for DNS locations
    u_DNS = cell(Nloc, 100); % U-velocity at each DNS location over time
    v_DNS = cell(Nloc, 100); % V-velocity at each DNS location over time
    w_DNS = cell(Nloc, 100); % W-velocity at each DNS location over time
    u_combined = cell(Nloc, 1); 
    v_combined = cell(Nloc, 1); 
    w_combined = cell(Nloc, 1); 

    slice_z = zeros(Nloc, 1);


    % figure;
    % tiledlayout(1, length(azimuth), "Padding", "loose", "TileSpacing", "loose");
    % set(gcf, 'Position', [200, 100, 800, 800]);
        
    for n = 1:DNS.ts_cycle
        N = N0 + n;
        
        % Define file paths for velocity data
        filePath = fullfile(cas.diransys_out, DNS.case + "_report-" + sprintf('%04d', N));            
        if ~exist(filePath, 'file')
            error('File "%s" does not exist.', fileName);
        end
        
        % Load velocity data
        fileID = fopen(filePath, 'r');
        data = textscan(fileID, '%d %f %f %f %f %f %f %f', 'HeaderLines', 1);
        fclose(fileID);
        
        if n == 1
            X = data{2} * 100;
            Y = data{3} * 100;
            Z = data{4} * 100;
            
            % Set plot limits
            XL = [min(X(:)) - 0.2, max(X(:)) + 0.2];
            YL = [min(Y(:)) - 0.2, max(Y(:)) + 0.2];
            ZL = [min(Z(:)) - 0.5, max(Z(:)) + 0.5];
        end
        
        % Velocity components
        W = data{5} * 100; % X component of velocity [cm/s]
        V = data{6} * 100; % Y component of velocity
        U = data{7} * 100; % Z component of velocity
        p = data{8}; % pressure
        
        % Plot the velocity data from different views
        
        %     for k = 1:length(azimuth)
        %         nexttile(k);
        %         quiver3(X, Y, Z, U, V, W, sc);
        %         hold on;
        %         scatter3(X_mesh, Y_mesh, Z_mesh, 1, 'filled');
        %         alpha(opacity_val);
        % 
        %         view(azimuth(k), elevation(k));
        %         xlim(XL);
        %         ylim(YL);
        %         zlim(ZL);
        % 
        %         set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01]);
        %         xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        %         ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        %         zlabel('Z [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        % 
        %         if k > 1
        %             set(gca, 'YColor', 'none');
        %             xlabel([]);
        %         end
        %         grid off;
        %         box off;    
        %         hold off;
        %         set(gca, 'Color', 'w');
        %         set(gcf, 'Color', 'w');
        %     % Update the title for the current frame
        %     title(sprintf('$t/T = %.2f$', tt(n)), 'Interpreter', 'latex', 'FontSize', fs+4);
        % 
        %     % Save the current axis handle
        %     prev_ax = gca; % Save the current axis before switching
        %     load(fullfile(cas.dirmat, "bottom_velocity.mat"),'q');
        % 
        %     % Switch to ax1 and plot - to be completed
        %     ax1 = axes('Position', [0.35 0.25 0.15 0.10]);
        %     flow_rate(q, 0)
        %     ylim([-2,2])
        %     hold on 
        %     xline(n/100,LineWidth=1)
        %     hold off
        %     set(gca,"FontSize",8)
        %     ylabel("$Q\left[{\rm ml/s}\right]$",'interpreter','latex','FontSize',12)
        %     xlabel("$t/T$",'interpreter','latex','FontSize',12)
        %     hold off
        % 
        %     % Return to the previous axis after plotting in ax1
        %     axes(prev_ax);  % Restore the previous axis
        % 
        %     movieVector(n) = getframe(gcf);
        % end
        % drawnow;

        % Read velocity results and organize data
            for i = 1:length(dat_PC.pixel_coord)
            % Extract the third component (:,:,3) and compute the mean
            slice_z(i) = mean(mean(dat_PC.pixel_coord{i}(:,:,3)));
            end
            slice_z(end-1) = slice_z(1) - DNS.delta_h_FM;
            slice_z(end) = max(Z(:))*10; % this is for the velocity at the top
            DNS.locz = slice_z/10;
            
        % Iterate over the locations
        for k = 1:length(DNS.locz)

            % for the first time step get x,y,z location slices
            if n == 1
                % Find all indices where Z falls within the range loc{k} ± 0.2
                index{k} = find(abs(Z - DNS.locz(k)) <= 0.2); 
                
                % Assign X, Y, Z coordinates for this location
                x_DNS{k} = X(index{k});
                y_DNS{k} = Y(index{k});
                z_DNS{k} = Z(index{k});
            end

            % Store the velocity components for the current time step (n)
            u_DNS{k,n} = U(index{k});
            v_DNS{k,n} = V(index{k});
            w_DNS{k,n} = W(index{k});
            
        end           
    end

    for k = 1:length(DNS.locz)
        % Combine all time steps into one array for each location (e.g., along the third dimension)
        u_combined{k} = cell2mat(u_DNS(k, :)); % Convert the cell array to a matrix
        v_combined{k} = cell2mat(v_DNS(k, :));
        w_combined{k} = cell2mat(w_DNS(k, :));
    end
       

    % Now, all the arrays have the same dimension, so we can use struct
    DNS.x = x_DNS;
    DNS.y = y_DNS;
    DNS.z = z_DNS;
    DNS.u = u_combined;
    DNS.v = v_combined;
    DNS.w = w_combined;
   
    save(fullfile(cas.dirmat,'DNS.mat'),'DNS');

    % Save the animation as a video
    % video_filename = "3D_velocity_animation";
    % myWriter = VideoWriter(fullfile(cas.dirvid, video_filename));
    % myWriter.FrameRate = 10;
    % open(myWriter);
    % writeVideo(myWriter, movieVector);
    % close(myWriter);