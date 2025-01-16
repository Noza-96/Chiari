%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clear; close all;

% Choose subject
subject = "s101";
session = 'before';

report = "c1";

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

addpath('Functions/');
addpath('Functions/Others/')

load(fullfile(cas.dirmat,"DNS.mat"),'DNS')
%% 2. Create 3D animations with velocity results into spinal canal geometry
animation_3D(cas, dat_PC, DNS)
load(fullfile(cas.dirmat,"DNS.mat"),'DNS')
%% 3. Obtain integral quantities
comparison_results(cas,dat_PC)

%% 3. Comparison PC-MRI with Ansys solution -- Animation
comparison_results(cas,dat_PC)

%% 4. Longitudinal impedance - Pressure drop and Flow rate
longitudinal_impedance(subject); 

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
