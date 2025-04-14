% Create figure with segmentation together with MRI locations
function save_pcmri_data(dat_PC, cas, ts_cycle)

    loc_ID = [1,dat_PC.Ndat];
    sstt = {"top", "bottom"};

    for ii = 1:dat_PC.Ndat

        % pcMRI velocity    
        U = -dat_PC.U_SAS{ii}*1e-2; % m/s
        xyz = dat_PC.pixel_coord{ii}*1e-3; %m
        Q = -dat_PC.Q_SAS{ii};  % Get flow data
    
        % Identify rows and columns where all elements are zero
        zeroRows = all(U(:,:,1) == 0, 2); % Logical vector for rows
        zeroCols = all(U(:,:,1) == 0, 1); % Logical vector for columns
        
        % Find the indices of the rows and columns to retain
        rowsToKeep = find(~zeroRows); 
        colsToKeep = find(~zeroCols);
        band = 1; 
	    rowsToKeep = (rowsToKeep(1)-band):1:(rowsToKeep(end)+band);
	    colsToKeep = (colsToKeep(1)-band):1:(colsToKeep(end)+band);
        
        % Extract the submatrix and update vectors
        U = U(rowsToKeep, colsToKeep,:);
        xyz = xyz(rowsToKeep, colsToKeep,:);
        
        U = reshape(U,[size(U,1)*size(U,2),size(U,3)]);
    
        %xyz coordinates
        xx = reshape(xyz(:,:,1),[],1);
        yy = reshape(xyz(:,:,2),[],1);
        zz = reshape(xyz(:,:,3),[],1);
        uu = zeros(size(U,1),ts_cycle);
        % We use the fourier approximation to go from 40 data points to 100
        for k=1:size(U,1)
            [uu(k,:), ~, ~] = four_approx(U(k,:), 20, 0, ts_cycle);
        end

        % Define points in millimeters
        x_coords = [xx(1), xx(floor(end/2)), xx(end)] * 1e3;
        y_coords = [yy(1), yy(floor(end/2)), yy(end)] * 1e3;
        z_coords = [zz(1), zz(floor(end/2)), zz(end)] * 1e3;
    
        x{ii} = xx; y{ii} = yy; z{ii} = zz;
        u{ii} = uu;

        [q{ii}, ~, ~] = four_approx(Q, 20, 0, ts_cycle); 

        t = linspace(0, 1, ts_cycle);  % Create time vector
        % Stroke volume
        SV{ii} = 0.5 * simps(t, abs(q{ii}), 2);  

        % Points P1, P2, P3
        P1 = [x_coords(1), y_coords(1), z_coords(1)];
        P2 = [x_coords(2), y_coords(2), z_coords(2)];
        P3 = [x_coords(3), y_coords(3), z_coords(3)];
        
        % Vectors on the plane
        V1 = P2 - P1;
        V2 = P3 - P1;
        
        % Normal vector to the plane
        nn = cross(V1, V2);
        
        % Normalize the normal vector
        nv{ii} = nn / norm(nn);

        %% Create plane pcMRI location
    
        % Open the file for writing                                 
        filename = fullfile(cas.diransys_in, "planes", cas.locations{ii}+".txt");
        % Create directory if it doesn't exist
        if ~exist(fileparts(filename), 'dir')
            mkdir(fileparts(filename));
        end
    
        fileID = fopen(filename, 'w');
        % Write the headers
        fprintf(fileID, '3d=True\n');
        fprintf(fileID, 'polyline=False\n\n');
    
        % Write the coordinates column by column
        data = [z_coords(:), x_coords(:), y_coords(:)];
        fprintf(fileID, '%f %f %f\n', data.');
    
        % Close the file
        fclose(fileID);

 %% ANSYS profiles and clip planes
        if any(loc_ID == ii)
            index = find(loc_ID == ii);
            % Open the file for writing
            filename = fullfile(cas.diransys_in, "planes", sstt{index}+"_plane.txt");
            fileID = fopen(filename, 'w');
            % Write the headers
            fprintf(fileID, '3d=True\n');
            fprintf(fileID, 'polyline=False\n\n');

            % Write the coordinates column by column
            data = [z_coords(:), x_coords(:), y_coords(:)];
            fprintf(fileID, '%f %f %f\n', data.');
        
            % Close the file
            fclose(fileID);
        
            fprintf('%s_plane.txt created ... \n', sstt{index});

            % Create CSV file
            filename = fullfile("Functions","empty_inlet_vel.csv");  
            data = readcell(filename);
            row = 10; 
            n_data = length(x{ii});
            data(row + (1:n_data), 1) = num2cell(x{ii}); % Update column 1
            data(row + (1:n_data), 2) = num2cell(y{ii}); % Update column 2
            data(row + (1:n_data), 3) = num2cell(z{ii}); % Update column 3
    
            data(8, 1) = {strcat(sstt{index}, "_vel")};
    
            if sstt{index} == "top"
                normal_vel = -uu;
            elseif sstt{index} == "bottom"
                normal_vel = uu;
            end

            for n=1:ts_cycle
                % Read the CSV file as a cell array to handle mixed types
                data(row + (1:n_data), 4) = num2cell(normal_vel(:, n));       
    
                % Convert the cell array to a table
                dataTable = cell2table(data);
                
                % Write the updated table back to the CSV file
                filename = fullfile(cas.diransys_in, "profiles", sstt{index}+"_prof_"+num2str(n)+".csv");
                writetable(dataTable, filename, 'WriteVariableNames', false);
            end
            fprintf('profile saved for %s pc-MRI measurement ...  \n', sstt{index});
        end

    end
    % Create the structure
    pcmri.x = x;
    pcmri.y = y;
    pcmri.z = z;
    pcmri.SV = SV;
    pcmri.u_normal = u;
    pcmri.normal_v = nv;
    pcmri.q = q;
    pcmri.locations = cas.locations;
    pcmri.locz = dat_PC.locz;
    pcmri.Ndat = dat_PC.Ndat;
    pcmri.Nt = ts_cycle;
    pcmri.case = 'PC-MRI';

    % Save the structure to a .mat file
    save(fullfile(cas.dirmat, "pcmri_vel"), 'pcmri');
end



