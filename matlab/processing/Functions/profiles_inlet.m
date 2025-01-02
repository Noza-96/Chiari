%Show animation velocity inlet together with flow rate measurement
function profiles_inlet (dat_PC, cas)

    location = [1,dat_PC.Ndat];
    sstt = {"top", "bottom"};

    for loc = 1:2

        index = location(loc);

        % pcMRI velocity    
        U = -dat_PC.U_SAS{index}*1e-2; % m/s
        xyz = dat_PC.pixel_coord{index}*1e-3; %m



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
        x = reshape(xyz(:,:,1),[],1);
        y = reshape(xyz(:,:,2),[],1);
        z = reshape(xyz(:,:,3),[],1);

        % coordinates to define the plane
        x_coords = [x(1), x(floor(end/2)), x(end)]*1e3;
        y_coords = [y(1), y(floor(end/2)), y(end)]*1e3;
        z_coords = [z(1), z(floor(end/2)), z(end)]*1e3;

        % Open the file for writing
        filename = cas.diransys_in + "/"+sstt{loc}+"_plane.txt";
        fileID = fopen(filename, 'w');
        % Write the headers
        fprintf(fileID, '3d=True\n');
        fprintf(fileID, 'polyline=False\n\n');

        % Write the coordinates column by column
        data = [z_coords(:), x_coords(:), y_coords(:)];
        fprintf(fileID, '%f %f %f\n', data.');

        % Close the file
        fclose(fileID);

        fprintf('%s_plane.txt created', sstt{loc});


        u=zeros(size(U,1),100);
        
        % We use the fourier approximation to fo from 40 data points to 100
        for k=1:size(U,1)
            [u(k,:), ~, ~] = four_approx(U(k,:),20,0);
        end

                figure
        % set(gcf,'Position',[100,100,400,600])
        for n = 1:100
            scatter(x*1e2, y*1e2, 10, u(:,n)*1e2, 'filled', 'd');
            bluetored(6)
            set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
            xlabel("$x$ [cm]",fontsize=16,Interpreter="latex")
            ylabel("$y$ [cm]",fontsize=16,Interpreter="latex")
            c = colorbar;
            c.Label.String = '[cm/s]';
            set(gca, 'View', [90 90]); % Rotates the axes
            title(""+sstt{loc}+ " velocity $t="+num2str((n)/100, '%.2f')+"$ s",'Interpreter','latex',FontSize=20)
            box on
            drawnow
        end        
    
        % Create CSV file
        filename = "empty_inlet_vel.csv";  
        data = readcell(filename);
        row = 10; 
        n_data = length(x);
        data(row + (1:n_data), 1) = num2cell(x); % Update column 1
        data(row + (1:n_data), 2) = num2cell(y); % Update column 2
        data(row + (1:n_data), 3) = num2cell(z); % Update column 3

        for n=1:size(u, 2)
            % Read the CSV file as a cell array to handle mixed types
            data(row + (1:n_data), 4) = num2cell(u(:, n)); % Update column 3       

            % Convert the cell array to a table
            dataTable = cell2table(data);
            
            % Write the updated table back to the CSV file
            filename = cas.diransys_in + "/"+sstt{loc}+"_prof_"+num2str(n)+".csv";
            writetable(dataTable, filename, 'WriteVariableNames', false);
            n
        end
        fprintf('data saved for %s\n pc-MRI measurement', sstt{loc});
        save(fullfile(cas.dirmat, sstt{loc}+"_velocity.mat"), 'x','y','z','u');


    end
end




