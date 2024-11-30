%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clear; close all;
addpath /Users/noza/Documents/MATLAB/Functions/;

% Choose subject
subject = "s101";

load("data/"+subject+"/03-apply_roi_compute_Q.mat");
% 
% top_seg = 65.7;
% 
% locz=[dat_PC.locz{1},dat_PC.locz{2},dat_PC.locz{3}]*10;
% names = cas.locations;
% Dz=11.9; %From Slicer
% 
% locations=top_seg-locz-Dz;
%% Calculate flow rate PC-MRI measurements
% Ansys_file = 'Chiari_Granada';
MRI_locations(subject,dat_PC,cas)
set(gcf, 'Color', 'w');
saveas(gcf,"Figures\"+subject+"\MRI_locations",'png')

% points_bottom = readmatrix("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG/Fluent/bottom.csv");
% points_boundaries = readmatrix("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG/Fluent/wall.csv");


% grid on 



% %% Create velocity measurements animations
% close all;
% u_MRI={-dat_PC.U_SAS{1},-dat_PC.U_SAS{2},-dat_PC.U_SAS{3}};
% create_animation_MRI(u_MRI,dat_PC.area_SAS,t)
%% Longitudinal impedance

load("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG-2/Fluent/dp.out", 'r');




%% Create 3D animation
close all
% Open the file
tt={"inlet"};

type="variable";

azimuth = [-45,0];
elevation = [10,5];

figure
tfig=tiledlayout(1,length(azimuth),"Padding","loose","TileSpacing","loose");
set(gcf,'pos',[200,200,1000,1000])
% grid on;

t=linspace(0,1,100);
N0 = 200-2;
fs = 14;

    


for n=1:100
    N=N0+n;
    fileID = fopen("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG/Fluent/MRI_locations_"+type+"/"+tt{1}+"-0"+N, 'r');
    meshID = fopen("../3. Ansys/"+Ansys_file+"_files/dp0/FLTG/Fluent/Surface", 'r');

    % Read the data from the file using textscan
    % Format: %d for nodenumber (integer), %f for the remaining floating-point values
    data = textscan(fileID, '%d %f %f %f %f %f %f', 'HeaderLines', 1);
    Mesh = textscan(meshID, '%d %f %f %f', 'HeaderLines', 1);
    
    if n==1
        X_mesh = Mesh{2}*100;
        Y_mesh = Mesh{3}*100;
        Z_mesh = Mesh{4}*100;
        X = data{2}*100;
        Y = data{3}*100;
        Z = data{4}*100;

        XL = [min(X(:))-0.5,max(X(:))+0.5];
        YL = [min(Y(:))-0.5,max(Y(:))+0.5];
        ZL = [min(Z(:))-1,max(Z(:))+1];
    end
    U = data{5}*100; % X component of velocity
    V = data{6}*100; % Y component of velocity
    W = data{7}*100; %cm/s 
    fclose(fileID);
    sc = 5;
    for k=1:length(azimuth)
        nexttile(k)
        quiver3(X, Y, Z, U, V, W, sc);
        hold on
        scatter3(X_mesh, Y_mesh, Z_mesh, 10, 'filled')
        alpha(0.07);
        % gm = importGeometry("chiari_ansys.STEP");
        % scale(gm,[10,10,10])
        % pdegplot(gm)

        view(azimuth(k), elevation(k))
        xlim(XL)
        ylim(YL)
        zlim(ZL)

        set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        xlabel('X [cm]','interpreter','latex',FontSize=fs);
        ylabel('Y [cm]','interpreter','latex',FontSize=fs);
        zlabel('Z [cm]','interpreter','latex',FontSize=fs);
        if k==1
            % addaxis(XL,YL,ZL)
        else
            set(gca, 'YColor', 'none')
        end
        grid off
        box off

        hold off 
        set(gca, 'Color', 'w');  % Ensures the background is white
        set(gcf, 'Color', 'w');  % Sets the figure background color to white
        
        

        
        % Optionally adjust the lighting, if desired
        % lighting gouraud;
        % camlight headlight;
    end
    title(tfig,sprintf('$t/T = %.2f$ ', t(n)),'interpreter','latex',fontsize=20);    
    
    drawnow
    movieVector(n) = getframe(gcf);

end
sstt="3D_velocity_"+type;
myWriter = VideoWriter(fullfile('Videos',sstt));
myWriter.FrameRate = 10;
open(myWriter);
writeVideo(myWriter,movieVector);
close(myWriter);



% Now the variables nodenumber, x_coordinate, y_coordinate, z_coordinate, and z_velocity 
% contain the respective data from the file


%% Create animations ANSYS simulations - uniform velocity field
close all
% Open the file
tt={"C1C2","C2C3","C3C4"};

N0 = 300;
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


% Now the variables nodenumber, x_coordinate, y_coordinate, z_coordinate, and z_velocity 
% contain the respective data from the file

%% 
function create_animation_MRI(u_MRI,A_MRI,t)


    figure; clf;
    tit=tiledlayout(length(u_MRI),1,TileSpacing="compact",Padding='compact');
    fs=14;
    set(gcf,'pos',[200,200,200,200*length(u_MRI)])
    xL=[200,0];
    yL=xL;
    for k=1:length(u_MRI)
        [Y,X,~]=find(u_MRI{k}(:,:,1));
        DX = (max(X)-min(X)+10)/2;
        X0 = (max(X)+min(X))/2;
        Y0 = (max(Y)+min(Y))/2;
        xL(1)=min(xL(1),X0-DX);
        xL(2)=max(xL(2),X0+DX);
        yL(1)=min(yL(1),Y0-DX);
        yL(2)=max(yL(2),Y0+DX);
    end

    for n=1:length(t)
        title(tit,sprintf('$t/T = %.2f$ ', t(n)),'interpreter','latex',fontsize=20);    
    
        for k=1:length(u_MRI)
            [Y,X,~]=find(u_MRI{k}(:,:,1));
            DX = (max(X)-min(X)+10)/2;
            X0 = (max(X)+min(X))/2;
            Y0 = (max(Y)+min(Y))/2;
            nexttile (k)
            imagesc(u_MRI{k}(:,:,n));
            bluetored(6);
            set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
            colorbar off;
            if k==length(u_MRI)
                xlabel('X [pixels]','interpreter','latex',FontSize=fs);
                ylabel('Y [pixels]','interpreter','latex',FontSize=fs);
            end
            ylim(yL)
            xlim(xL)
            % title(""+cas.locations{loc},'Interpreter','latex',FontSize=16)
        end
        movieVector(n) = getframe(gcf);
    end
    sstt='MRI_vel_profiles';
    myWriter = VideoWriter(fullfile('Videos',sstt));
    myWriter.FrameRate = 5;
    open(myWriter);
    writeVideo(myWriter,movieVector);
    close(myWriter);
end

%%


function flow_rate(Q,n,Nt)
    blue = [116,124,187]/255;  red = [241,126,126]/255;
    t=linspace(0,1,Nt);
    plot(t,Q,'-',LineWidth=1.5,Color='k')
    hold on
    Q_neg=Q.*(Q<0);
    area(t,Q,'Facecolor',red);
    area(t,Q_neg,'Facecolor',blue);
    set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
    set(gca,'FontSize',12)
    if n>0
        plot(t(n),Q(n),'o',MarkerFaceColor=[0.7,0.7,0.7],MarkerEdgeColor='k',MarkerSize=8,LineWidth=1)
    end
    plot(t,n*0,'-',LineWidth=1,Color='k')  
end

function addaxis(x,y,z)
    origin = [0, 0, 0];
    arrow_length = 0.1 * min([max(x)-min(x), max(y)-min(y), max(z)-min(z)]); % Small length relative to plot size
    arrowhead_size = arrow_length * 0.4;
    % X-axis arrow (red)
    quiver3(origin(1), origin(2), origin(3), arrow_length, 0, 0, 'k', 'LineWidth', 1, 'MaxHeadSize', 0);
    % text(arrow_length, 0, 0, 'X', 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
   
    % Y-axis arrow (green)
    quiver3(origin(1), origin(2), origin(3), 0, arrow_length, 0, 'k', 'LineWidth', 1, 'MaxHeadSize', 0);
    % text(0, arrow_length, 0, 'Y', 'Color', 'g', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Z-axis arrow (blue)
    quiver3(origin(1), origin(2), origin(3), 0, 0, arrow_length, 'k', 'LineWidth', 1, 'MaxHeadSize', 0);
    % text(0, 0, arrow_length, 'Z', 'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');


    % X-axis arrowhead (red)
    x_head = [arrow_length, arrow_length-arrowhead_size, arrow_length-arrowhead_size];
    y_head = [0, arrowhead_size/2, -arrowhead_size/2];
    z_head = [0, 0, 0];
    patch(x_head, y_head, z_head, 'k', 'EdgeColor', 'none');  % Filled triangle for X-axis
    
    % Y-axis arrowhead (green)
    x_head = [0, arrowhead_size/2, -arrowhead_size/2];
    y_head = [arrow_length, arrow_length-arrowhead_size, arrow_length-arrowhead_size];
    z_head = [0, 0, 0];
    patch(x_head, y_head, z_head, 'k', 'EdgeColor', 'none');  % Filled triangle for Y-axis
    
    % Z-axis arrowhead (blue)
    x_head = [0, 0, 0];
    y_head = [0, arrowhead_size/2, -arrowhead_size/2];
    z_head = [arrow_length, arrow_length-arrowhead_size, arrow_length-arrowhead_size];
    patch(x_head, y_head, z_head, 'k', 'EdgeColor', 'none');  % Filled triangle for Z-axis
end

function MRI_locations(subject,dat_PC,cas)
    fig1=openfig("../2. Flow_rate_MRI/dat/"+subject+"/flow/20240606am-card/fig/orientation_of_planes_PC.fig",'invisible');
    ax1 = gca; % Get the axes of the loaded figure
    row=4;
    figure
    set(gcf,'pos',[200,200,1000,600])
    tt = tiledlayout(3, row*2,"TileSpacing","tight","Padding","tight");
    % First tile - Use the existing figure
    nexttile([3,2*2]);
    axesObjs = findobj(ax1, 'Type', 'axes');  % Find all axes objects
    copyobj(get(axesObjs, 'Children'), gca);  % Copy all objects (like plots, lines, etc.) to new tile
    view(90,15)
    zlim([-140,-40])
    axis off
    Vs=zeros(1,length(dat_PC.Q_SAS));
    for k=1:length(dat_PC.Q_SAS)
        Q=-dat_PC.Q_SAS{k};
        Nt = dat_PC.Nt{k};
        t=linspace(0,1,Nt);
        nexttile (5+(k-1)*row*2,[1,2])
        Vs(k)=0.5*simps(t,abs(Q),2);
        flow_rate(Q,0,length(t))
        if k<length(dat_PC.Q_SAS)
            xticklabels([])
        else
            xlabel("$t/T$",'interpreter','latex',FontSize=20);
        end
        ylabel("$Q\left[{\rm ml/s}\right]$",'interpreter','latex',FontSize=20);
        ylim([-2,2])
        title(""+cas.locations{k},'Interpreter','latex',FontSize=16)
    end
    xticks(0:0.2:1)
    
    nexttile ([3,1])
    plot(Vs,3:-1:1,'o-',LineWidth=1.5)
    yticks([])
    % yticklabels(flip(cas.locations))
    set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
    set(gca,'FontSize',12)
    title("$V_s$",Interpreter="latex",FontSize=16)
    xlim([floor(min(Vs(:)) / 0.05) * 0.05, ceil(min(Vs(:)) / 0.05) * 0.05]);
end