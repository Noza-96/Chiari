
clear; close all; 


subject = 's101'; 
load("data/"+subject+"/ansys_outputs/DNS.mat");



%% Create animations ANSYS simulations - uniform velocity fiel
N0 = 100;
fs = 14;

for k=1:length(tt)
    figure
    set(gcf,'pos',[200*(2*k-1),200,500,400])
    for n=1:100
        N=N0+n;
        fileID = fopen("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG/Fluent/MRI_locations/"+tt{k}+"-0"+N, 'r');
        % Read the data from the file using textscan
        % Format: %d for nodenumber (integer), %f for the remaining floating-point values
        data = textscan(fileID, '%d %f %f %f %f', 'HeaderLines', 1);
        if n==1
            x_coordinate = data{2}*100;
            y_coordinate = data{3}*100;
            % Define the grid points for interpolation (you can adjust the resolution of the grid)
            xq = linspace(min(x_coordinate), max(x_coordinate), 1000); % 100 points in x-direction
            yq = linspace(min(y_coordinate), max(y_coordinate), 1000); % 100 points in y-direction

            % Create a meshgrid from these points
            [Xq, Yq] = meshgrid(xq, yq);
        end

        
        z_velocity = data{5}*100;
        fclose(fileID);
                % Interpolate z_velocity onto the grid using scattered data
        Zq = griddata(x_coordinate, y_coordinate, z_velocity, Xq, Yq, 'cubic');

        % Plot the contour
        contourf(Xq, Yq, Zq, 20, 'LineColor', 'none'); % '20' specifies the number of contour levels (adjust as needed)
        colorbar; % Add a color bar to indicate the z_velocity scale
        title('2D Contour Plot of z-velocity');
        xlabel('X [cm]','interpreter','latex',FontSize=fs);
        ylabel('Y [cm]','interpreter','latex',FontSize=fs);

        % scatter(x_coordinate, y_coordinate, 100, z_velocity, 'filled', 'd'); % Interpolated point

        title (tt{k},Interpreter="latex",FontSize=20)
        set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        colorbar
        bluetored(6)
        box on
        
        hold off 
        axis equal
        movieVector(n) = getframe(gcf);

    end
        sstt="Ansys_velocities_uniform_"+tt{k};
        myWriter = VideoWriter(fullfile('Videos',sstt));
        myWriter.FrameRate = 5;
        open(myWriter);
        writeVideo(myWriter,movieVector);
        close(myWriter);
end