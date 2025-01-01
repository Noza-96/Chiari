%Show animation velocity inlet together with flow rate measurement
function profiles_inlet (dat_PC, cas)

    location = [1,dat_PC.Ndat];
    sstt = {"top", "bootom"};

    for loc = 1:2

        % pcMRI velocity    
        U = -dat_PC.U_SAS{location(loc)}*1e-2; % m/s
        U = reshape(U,[size(U,1)*size(U,2),size(U,3)]);
        
        %xyz coordinates
        xyz = dat_PC.pixel_coord{location(loc)}*1e-3; %m
        x = reshape(xyz(:,:,1),[],1);
        y = reshape(xyz(:,:,2),[],1);
        z = reshape(xyz(:,:,3),[],1);

     
    
        u=zeros(size(U,1),100);
        
        % We use the fourier approximation to fo from 40 data points to 100
        for k=1:size(U,1)
            [u(k,:), ~, ~] = four_approx(U(k,:),20,0);
        end
        disp('1 done')

        
    
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
        fprintf('Data saved for %s\n', sstt{loc});
        Q=mean(u,1)*A;
        save(fullfile(cas.dirdat,sstt{loc}+"_velocity.mat"), 'x','y','z','u','Q');

        % figure
        % % set(gcf,'Position',[100,100,400,600])
        % for n = 1:100
        %     scatter(x*1e2, y*1e2, 10, u(:,n)*1e2, 'filled', 'd');
        %     bluetored(6)
        %     set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        %     xlabel("$x$ [cm]",fontsize=16,Interpreter="latex")
        %     ylabel("$y$ [cm]",fontsize=16,Interpreter="latex")
        %     c = colorbar;
        %     c.Label.String = '[cm/s]';
        %     set(gca, 'View', [90 90]); % Rotates the axes
        %     title(""+sstt{loc}+ " velocity $t="+num2str((n)/100, '%.2f')+"$ s",'Interpreter','latex',FontSize=20)
        %     box on
        %     drawnow
        % end  
    end
end




