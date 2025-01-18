%Show animation velocity inlet together with flow rate measurement

%TO-DO save all data in struct dat_PC.velocity.(x,y,z,u,n,q)
function velocity_profiles (dat_PC, cas, ts_cycle)

    location = [1,dat_PC.Ndat];
    sstt = {"top", "bottom"};

    x = cell(1,dat_PC.Ndat);
    y = cell(1,dat_PC.Ndat);
    z = cell(1,dat_PC.Ndat);
    u = cell(1,dat_PC.Ndat);
    q = cell(1,dat_PC.Ndat);
    n = cell(1,dat_PC.Ndat);

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
        x{ii} = reshape(xyz(:,:,1),[],1);
        y{ii} = reshape(xyz(:,:,2),[],1);
        z{ii} = reshape(xyz(:,:,3),[],1);
        uu = zeros(size(U,1),ts_cycle);
        % We use the fourier approximation to go from 40 data points to 100
        for k=1:size(U,1)
            [uu(k,:), ~, ~] = four_approx(U(k,:), 20, 0, ts_cycle);
        end
        u{ii} = uu;
        [q{ii}, ~, ~] = four_approx(Q, 20, 0, ts_cycle); 

        % Define points in millimeters
        x_coords = [x(1), x(floor(end/2)), x(end)] * 1e3;
        y_coords = [y(1), y(floor(end/2)), y(end)] * 1e3;
        z_coords = [z(1), z(floor(end/2)), z(end)] * 1e3;
        
        % Points P1, P2, P3
        P1 = [x_coords(1), y_coords(1), z_coords(1)];
        P2 = [x_coords(2), y_coords(2), z_coords(2)];
        P3 = [x_coords(3), y_coords(3), z_coords(3)];
        
        % Vectors on the plane
        V1 = P2 - P1;
        V2 = P3 - P1;
        
        % Normal vector to the plane
        n{ii} = cross(V1, V2);
        
        % Normalize the normal vector
        n{ii} = n / norm(n);

        % Open the file for writing
        filename = cas.diransys_in + "/"+sstt{loc}+"_plane.txt";
        fileID = fopen(filename, 'w');
        % Write the headers
        fprintf(fileID, '3d=True\n');
        fprintf(fileID, 'polyline=False\n\n');

        % for the planes in which we want to output plane information
        if any(location == ii)
            % Write the coordinates column by column
            data = [z_coords(:), x_coords(:), y_coords(:)];
            fprintf(fileID, '%f %f %f\n', data.');
        
            % Close the file
            fclose(fileID);
        
            fprintf('%s_plane.txt created ... \n ', sstt{ii});

            % Create CSV file
            filename = "empty_inlet_vel.csv";  
            data = readcell(filename);
            row = 10; 
            n_data = length(x{ii});
            data(row + (1:n_data), 1) = num2cell(x{ii}); % Update column 1
            data(row + (1:n_data), 2) = num2cell(y{ii}); % Update column 2
            data(row + (1:n_data), 3) = num2cell(z{ii}); % Update column 3
    
            data(8, 1) = {strcat(sstt{ii}, "_vel")};
    
            for n=1:ts_cycle
                % Read the CSV file as a cell array to handle mixed types
                data(row + (1:n_data), 4) = num2cell(uu(:, n)); % Update column 3       
    
                % Convert the cell array to a table
                dataTable = cell2table(data);
                
                % Write the updated table back to the CSV file
                filename = cas.diransys_in + "/profiles/"+sstt{loc}+"_prof_"+num2str(n)+".csv";
                writetable(dataTable, filename, 'WriteVariableNames', false);
            end
            fprintf('profile saved for %s pc-MRI measurement ...  \n', sstt{loc});
        end
        
    end

    save(fullfile(cas.dirmat, sstt{loc}+"PCmri.mat"), 'x','y','z','u','q');

end



        %         figure
        % set(gcf,'Position',[100,100,400,600])
        % for n = 1:100
        %     scatter(x*1e2, y*1e2, 10, u(:,n)*1e2, 'filled', 'd');
        %     bluetored(6)
        %     set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        %     xlabel("$x$ [cm]",fontsize=16,Interpreter="latex")
        %     ylabel("$y$ [cm]",fontsize=16,Interpreter="latex")
        %     c = colorbar;
        %     c.Label.String = '[cm/s]';
        %     % set(gca, 'View', [90 90]); % Rotates the axes
        %     title(""+sstt{loc}+ " velocity $t="+num2str((n)/100, '%.2f')+"$ s",'Interpreter','latex',FontSize=20)
        %     box on
        %     drawnow
        % end        
   






