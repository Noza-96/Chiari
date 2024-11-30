function animation_3D(subject, animation)
    disp('2. Transfer ansys outputs to matlab and create 3D flow animations:')
    % 3D Animation for Velocity Output
    load("data/" + subject + "/03-apply_roi_compute_Q.mat");
    % Visualization settings
    azimuth = [-45, 0];
    elevation = [10, 5];
    tt = linspace(0, 1, 100);
    cycle = 3;
    N0 = (cycle-1) * 100 - 2;
    % N0 = 48;
    fs = 10; 
    subfolder = {'FLTG', 'FLTG-2'};
    type = {'variable','uniform'};
    
    % Define source and destination folders
    ansys_folder = "data/" + subject + "/ansys_outputs/";
    source_file = "../3. Ansys/" + subject + "_files/dp0/FLTG/Fluent/Surface";
    destination_file = ansys_folder + "Surface_Mesh";
    
    % Check if the surface mesh exists or move it if needed
    if isfile(source_file)
        movefile(source_file, destination_file);
        fprintf('\tAnsys mesh successfully transfered!\n');
    elseif isfile(destination_file)
        fprintf('\tansys mesh file already exists in the destination folder...\n');
    else
        error('File "Surface" containing the geometry surface mesh needs to be created in ANSYS.\n');
    end
    
    % Load mesh data
    meshID = fopen(destination_file, 'r');
    Mesh = textscan(meshID, '%d %f %f %f', 'HeaderLines', 3);
    X_mesh = Mesh{2} * 100;
    Y_mesh = Mesh{3} * 100;
    Z_mesh = Mesh{4} * 100;
    fclose(meshID);
    ID_struc = cell (1,2);

    
    % Loop over the two configurations
    for conf = 1:2
        % Initialize the indices and data storage arrays
        index = cell(1, 5); % Preallocate for index lookup
        x_DNS = cell(5, 1); % X-coordinates for DNS locations
        y_DNS = cell(5, 1); % Y-coordinates for DNS locations
        z_DNS = cell(5, 1); % Z-coordinates for DNS locations
        u_DNS = cell(5, 100); % U-velocity at each DNS location over time
        v_DNS = cell(5, 100); % V-velocity at each DNS location over time
        w_DNS = cell(5, 100); % W-velocity at each DNS location over time
        u_combined = cell(5, 1); 
        v_combined = cell(5, 1); 
        w_combined = cell(5, 1); 

        SourceFolder = "../3. Ansys/" + subject + "_files/dp0/" + subfolder{conf} + "/Fluent/";
        source_file = SourceFolder + "dp.out";
        destination_file = fullfile(ansys_folder, subfolder{conf}, 'dp.out');

        if isfile(source_file)
            movefile(source_file, destination_file);
            fprintf('\tCase %d: Pressure results successfully transfered!\n', conf);

        elseif isfile(destination_file)
            fprintf('\tCase %d: Pressure data already exist in the destination folder...\n', conf);
        else
            error('Ansys simulation needs to be done.');
        end

        fileID = fopen(destination_file, 'r');
        p_data = textscan(fileID, '%f %f %f %f', 'HeaderLines', 3, 'Delimiter', {' ', '\t'}, 'MultipleDelimsAsOne', true);

        % p_data = textscan(fileID, '%d %f %f %f', 'HeaderLines', 1);
        fclose(fileID);      
        dp = p_data{2};
        t = p_data{3};
        Q = p_data{4};

       save(fullfile(ansys_folder, subfolder{conf}, 'flow_data.mat'), 'dp', 't', 'Q');


        if animation == 1
            sc = 5; % Scale factor for velocity vectors
            figure;
            tfig{conf} = tiledlayout(1, length(azimuth), "Padding", "loose", "TileSpacing", "loose");
            set(gcf, 'Position', [200, 100, 800, 800]);
        end
        
        for n = 1:100
            N = N0 + n;
            
            % Define file paths for velocity data
            file_name = "vel-" + sprintf('%04d', N);
            source_file = SourceFolder + file_name;
            destination_file = fullfile(ansys_folder, subfolder{conf}, file_name);
            
            
            % Check if the velocity file exists or move it if needed
            if isfile(source_file)
                movefile(source_file, destination_file);
                if n == 1 
                    fprintf('\t%*sVelocity results successfully transfered!\n', length('Case 1: '), ' ');
                end
            elseif isfile(destination_file)
                if n == 1
                    fprintf('\t%*sVelocity results already exist in the destination folder...\n', length('Case 1: '), ' ');
                end
            else
                error('Ansys simulation needs to be done.');
            end

            
            % Load velocity data
            fileID = fopen(destination_file, 'r');
            data = textscan(fileID, '%d %f %f %f %f %f %f', 'HeaderLines', 1);
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
            U = data{5} * 100; % X component of velocity [cm/s]
            V = data{6} * 100; % Y component of velocity
            W = data{7} * 100; % Z component of velocity
            
            % Plot the velocity data from different views
            
            if animation == 1
                for k = 1:length(azimuth)
                    nexttile(k);
                    quiver3(X, Y, Z, U, V, W, sc);
                    hold on;
                    scatter3(X_mesh, Y_mesh, Z_mesh, 1, 'filled');
                    alpha(0.05);
    
                    view(azimuth(k), elevation(k));
                    xlim(XL);
                    ylim(YL);
                    zlim(ZL);
    
                    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01]);
                    xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
                    ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
                    zlabel('Z [cm]', 'Interpreter', 'latex', 'FontSize', fs);
    
                    if k > 1
                        set(gca, 'YColor', 'none');
                        xlabel([]);
                    end
                    grid off;
                    box off;    
                    hold off;
                    set(gca, 'Color', 'w');
                    set(gcf, 'Color', 'w');
                end 
            % Update the title for the current frame
            title(tfig{conf}, sprintf('$t/T = %.2f$', tt(n)), 'Interpreter', 'latex', 'FontSize', fs+4);
    
            % Save the current axis handle
            prev_ax = gca; % Save the current axis before switching
            
            % Switch to ax1 and plot
            ax1 = axes('Position', [0.35 0.25 0.15 0.10]);
            flow_rate(Q(end-99:end)*1e6, 0)
            ylim([-2,2])
            hold on 
            xline(n/100,LineWidth=1)
            hold off
            set(gca,"FontSize",8)
            ylabel("$Q\left[{\rm ml/s}\right]$",'interpreter','latex','FontSize',12)
            xlabel("$t/T$",'interpreter','latex','FontSize',12)
       
            % Return to the previous axis after plotting in ax1
            axes(prev_ax);  % Restore the previous axis
            
            drawnow;
            movieVector(n) = getframe(gcf);
            end

            % Read velocity results and organize data
            loc = [{min(abs(Z(:)))}, dat_PC.locd(:)', {max(abs(Z(:)))}]; % Assuming locd is part of a structure dat_PC
            name_loc = [{"outlet"}, cas.locations(:)', {"inlet"}]'; % Assuming cas is a predefined structure
               
                
            % Iterate over the locations
            for k = 1:length(loc)
                if n == 1
                    % Find all indices where Z falls within the range loc{k} ± 0.2
                    index{k} = find(abs(Z + loc{k}) <= 0.2); 
                    
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
        
        % In the source folder, delete remaining files starting with 'vel-'
        filePattern = fullfile(SourceFolder, 'vel-*');
        
        % Get a list of all files matching the pattern
        fileList = dir(filePattern);
        
        % Loop through the list and delete each file
        for k = 1:length(fileList)
            delete(fullfile(SourceFolder, fileList(k).name));
        end


        for k = 1:5
            % Combine all time steps into one array for each location (e.g., along the third dimension)
            u_combined{k} = cell2mat(u_DNS(k, :)); % Convert the cell array to a matrix
            v_combined{k} = cell2mat(v_DNS(k, :));
            w_combined{k} = cell2mat(w_DNS(k, :));
        end
       

        % Now, all the arrays have the same dimension, so we can use struct
        ID_struc {conf} = struct('x', x_DNS, 'y', y_DNS, 'z', z_DNS, ...
                     'u', u_combined, 'v', v_combined, 'w', w_combined, ...
                     'locations', name_loc);
        if animation == 1
            % Save the animation as a video
            video_filename = "3D_velocity_" + type{conf};
            myWriter = VideoWriter(fullfile('Videos', subject, 'post', video_filename));
            myWriter.FrameRate = 10;
            open(myWriter);
            writeVideo(myWriter, movieVector);
            close(myWriter);
        end
    end
    DNS = struct('Variable', ID_struc{1}, 'Uniform', ID_struc{2});
    save("data/"+subject+"/ansys_outputs/DNS.mat",'DNS');
end
