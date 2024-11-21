%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clear; close all;

% Choose subject
subject = "s101";

[cas, dat_PC] = load_data(subject);

%% 2. Create 3D animations with velocity results into spinal canal geometry
animation_3D(subject, 0)

%% 3. Comparison PC-MRI with Ansys solution -- Animation
close all
% Open the file
type = {'Uniform','Variable'};
load("data\"+subject+"\ansys_outputs\DNS.mat");
fs = 14;
loc_MRI = cas.locations;
figure
tit=tiledlayout(5,3,"TileSpacing","tight","Padding","loose");
set(gcf,'pos',[100,000,1000,1000])
%For each time-step
for n=1:100
    % We do it for each PC-MRI measurement
    create_animation_MRI(dat_PC,n)
    % We do it for Uniform simulation
    create_animation_ansys(DNS.Uniform,n,0)
    % We do it for Variable simulation
    create_animation_ansys(DNS.Variable,n,1)
    title(tit,sprintf('$t/T = %.2f$ ', n/100),'interpreter','latex',fontsize=20);    
    movieVector(n) = getframe(gcf);
    drawnow;
end
sstt="2D_velocity_comparisons";
myWriter = VideoWriter(fullfile('Videos',subject,'post',sstt));
myWriter.FrameRate = 5;
open(myWriter);
writeVideo(myWriter,movieVector);
close(myWriter);



%% 4. Longitudinal impedance - Pressure drop and Flow rate

%% Create animations ANSYS simulations - uniform velocity field

% 
% for k=1:location
%     figure
%     set(gcf,'pos',[200*(2*k-1),200,500,400])
% 
% 
% 
%         z_velocity = data{5}*100;
%         fclose(fileID);
%                 % Interpolate z_velocity onto the grid using scattered data
%         Zq = griddata(x_coordinate, y_coordinate, z_velocity, Xq, Yq, 'cubic');
% 
%         % Plot the contour
%         contourf(Xq, Yq, Zq, 20, 'LineColor', 'none'); % '20' specifies the number of contour levels (adjust as needed)
%         colorbar; % Add a color bar to indicate the z_velocity scale
%         title('2D Contour Plot of z-velocity');
%         xlabel('X [cm]','interpreter','latex',FontSize=fs);
%         ylabel('Y [cm]','interpreter','latex',FontSize=fs);
% 
%         % scatter(x_coordinate, y_coordinate, 100, z_velocity, 'filled', 'd'); % Interpolated point
% 
%         title (tt{k},Interpreter="latex",FontSize=20)
%         set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
%         colorbar
%         bluetored(6)
%         box on
% 
%         hold off 
%         axis equal
%         movieVector(n) = getframe(gcf);
% 
%     end
%         sstt="Ansys_velocities_uniform_"+tt{k};
%         myWriter = VideoWriter(fullfile('Videos',sstt));
%         myWriter.FrameRate = 5;
%         open(myWriter);
%         writeVideo(myWriter,movieVector);
%         close(myWriter);
% end


% Now the variables nodenumber, x_coordinate, y_coordinate, z_coordinate, and z_velocity 
% contain the respective data from the file

%% 
function create_animation_MRI(dat_PC,n)
    u_MRI = dat_PC.U_SAS;
    fs=14;
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
    for k=1:length(u_MRI)
        nexttile (4+(k-1)*3)
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
    end
end

function create_animation_ansys(data,n,index)
fs = 14;
    for loc = 1:length(data)
        x = data(loc).x;
        y = data(loc).y;
        % Define the grid points for interpolation (you can adjust the resolution of the grid)
        xq = linspace(min(x), max(x), 1000); % 1000 points in x-direction
        yq = linspace(min(y), max(y), 1000); % 1000 points in y-direction

        % Create a meshgrid from these points
        [Xq, Yq] = meshgrid(xq, yq);

        w = data(loc).w;
        % Interpolate w onto the grid using scattered data
        Zq = griddata(x, y, w(:,n), Xq, Yq, 'cubic');
        
        ax=nexttile(2+index+(loc-1)*3);
        % Plot the contour
        % contourf(Xq, Yq, Zq, 20, 'LineColor', 'none'); % '20' specifies the number of contour levels (adjust as needed)
        scatter(x, y, 8, w(:,n), 'filled', 'd');        
        colorbar; % Add a color bar to indicate the w scale
        if loc == length(data)
            xlabel('X [cm]','interpreter','latex',FontSize=fs);
            ylabel('Y [cm]','interpreter','latex',FontSize=fs);
        end
        set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        bluetored(6)
        if index == 0
            colorbar off
        end

        box on
        hold off 
        Dx = max(x(:))-min(x(:));
        Dy = max(y(:))-min(y(:));
        % axis equal
        xlim([min(x(:))-Dx*0.1,max(x(:))+Dx*0.1])
        ylim([min(y(:))-Dy*0.1,max(y(:))+Dy*0.1])

        pos = ax.Position;

        if loc == 1
            x_loc = 0;
        end

        if index == 1 & n==1
            y_loc = pos(2)-pos(4)*0.2;
            annotation('textbox', [x_loc, y_loc, 0.08, 0.1], 'String', "\textbf{{"+data(loc).locations+":}}", ...
           'Interpreter', 'latex', 'EdgeColor', 'none','HorizontalAlignment', 'right');
        end
    end
end
