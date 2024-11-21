%Show animation velocity inlet together with flow rate measurement
function profiles_inlet (subject, example_animation)

    load("data/"+subject+"/inlet_velocity.mat",'u','x','y','A')
    
    U = horzcat(u{:})*1e-2; %m/s
    
    Uf=zeros(size(U,1),100);
    
    for k=1:size(U,1)
        [Uf(k,:), ~, ~] = four_approx(U(k,:),20,0);
    end
    
    % Qf=mean(Uf,1)*A*1e4; %[ml/s]
    
    
    if example_animation == 1
        figure
        tiledlayout(2,1,"TileSpacing","compact",Padding="compact")
        set(gcf,'Position',[100,100,400,600])
        for n = 1:100
            nexttile(1)
            scatter(x*1e3, y*1e3, 100, Uf(:,n)*1e2, 'filled', 'd');
            bluetored(6)
            set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
            c = colorbar;
            c.Label.String = '[cm/s]';
            title("Inlet velocity $t="+num2str((n)/100, '%.2f')+"$ s",'Interpreter','latex',FontSize=20)
            box on
            nexttile(2)
            flow_rate(mean(Uf,1)*A*1e6,n)
            drawnow
        end
    end
    
     
    % Create CSV file
    
    % Define file name
    for n=1:size(Uf, 2)
        filename = "data/"+subject+"/empty_inlet_vel.csv";  
        % Read the CSV file as a cell array to handle mixed types
        data = readcell(filename);
        
        % Specify the row and columns to update
        row = 10;
        Col = 4;
        numValues = size(Uf, 2);

        for i = 1:size(Uf, 1)
            % for j = 1:size(Uf, 2)
                data{row + i, Col} = Uf(i, n);
            % end
        end
        
        
        % Convert the cell array to a table
        dataTable = cell2table(data);
        
        % Write the updated table back to the CSV file
        filename = "data/"+subject+"/ansys_inputs/FLTG/inlet_"+num2str(n)+".csv";
        writetable(dataTable, filename, 'WriteVariableNames', false);
    end
    Qf=mean(Uf,1)*A;
    save("data/"+subject+"/inlet_velocity.mat", 'Uf','Qf', '-append');
end




