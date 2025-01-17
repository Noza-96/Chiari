% 1. Preprocessing after running PC-MRI
clear; close all;

% Choose subject
subject = "s101";
session = 'before';
DNS.case = "c1";

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

% full ansys folder path
DNS.ansys_path = "C:/Users/guill/Documents/chiari/computations/ansys";

% ansys working folder
DNS.path_out_report = fullfile(cas.diransys, cas.subj+"_files", "dp0", "FLTG", "Fluent", DNS.case+"_variables.out");


DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
DNS.slices.locations = [cas.locations(1:end-1), "bottom", "FM-25", "top"]';
% DNS.locz = [dat_PC.locz{1:end}, dat_PC.locz{1}+2.5, NaN];
DNS.cycles = 3;
DNS.delta_h_FM = 25;
DNS.iterations_ts = 20;
DNS.ts_cycle = 100;


addpath('Functions/');
addpath('Functions/Others/')

save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')

%% 2. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(dat_PC, cas);

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(dat_PC, cas, 30, DNS.ts_cycle);

%% 4. Create CSV files with velocity field information for top and bottom locations
velocity_profiles (dat_PC, cas, DNS.ts_cycle);

%% 5. TUIs to be loaded in ANSYS

% TODO: create TUI to setup simulation 

% Create pcmri surfaces in ansys and surface
create_surfaces_journal_TUI(dat_PC, cas);

% Reports
reports_journal_TUI(cas, DNS)

% Script to run simulation
run_simulation_TUI(dat_PC, cas, DNS.cycles, DNS.iterations_ts, DNS.ts_cycle, DNS.ansys_path)

%% 4. Velocity profiles to ansys
% clear; close all;

% Choose subject
subject = "s101";
session = 'before';

sstt = {"top", "bottom"};
loc = 2;
index = 4;
n = 50;

load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","01-read_dat.mat"));

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

% pcMRI velocity    
uu = -dat_PC.U_SAS{index}; % m/s
uu = reshape(uu(:,:,ceil(end/2)),[],1)*100;
xyz = dat_PC.pixel_coord{index}*1e1; %m
xx = reshape(xyz(:,:,1),[],1)*1e-1;
yy = reshape(xyz(:,:,2),[],1)*1e-1;
zz = reshape(xyz(:,:,3),[],1)*1e-1;

hold on 
scatter3(xx, yy, zz, 20, uu, 'filled'); % 3D scatter plot

%% 
addpath('Functions/');
addpath('Functions/Others/')

load(fullfile(cas.dirmat, sstt{loc}+"_velocity.mat"))

scatter(x*1e2, y*1e2, 10, u(:,n)*1e2, 'filled', 'd');
bluetored(6)
set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
xlabel("$x$ [cm]",fontsize=16,Interpreter="latex")
ylabel("$y$ [cm]",fontsize=16,Interpreter="latex")
c = colorbar;
c.Label.String = '[cm/s]';
set(gca, 'View', [90 90]); % Rotates the axes
title(""+sstt{loc}+ " velocity $t="+num2str((n)/100, '%.2f')+"$ s",'Interpreter','latex',FontSize=20)
axis equal
box on

destination_file = fullfile(cas.diransys_out,"bottom_ans_geometry");
meshID = fopen(destination_file, 'r');
Mesh = textscan(meshID, '%d %f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
X_mesh = Mesh{2} * 100;
Y_mesh = Mesh{3} * 100;
Z_mesh = Mesh{4} * 100;
U = Mesh{5} * 100;
fclose(meshID);
figure; % Create a new figure
scatter3(X_mesh, Y_mesh, Z_mesh, 20, U, 'filled'); % 3D scatter plot
colorbar; % Add a color bar to show the velocity magnitude
xlabel('X (cm)'); % Label for the x-axis
ylabel('Y (cm)'); % Label for the y-axis
zlabel('Z (cm)'); % Label for the z-axis
title('3D Scatter Plot of Mesh Coordinates');
axis equal
hold on 
nonzero_indices = u(:,n) ~= 0;
scatter3(x(nonzero_indices)*1e2, y(nonzero_indices)*1e2, z(nonzero_indices)*1e2, 10, u(nonzero_indices,n)*1e2, 'filled'); % 3D scatter plot
grid on; % Enable grid for better visualization

scatter3(xx, yy, zz, 5, uu, 'filled'); % 3D scatter plot


%% 4. Transform MRI measurements for ANSYS inlet velocity profile - Variable (Here we change sign of velocity)
MRI_to_ansys_inlet_velocity(subject, dat_PC, 0);

%% 5. Generate journal file for variable velocity ANSYS simulation
velocity_inlet_journal(subject);

%% 6. Transfer data into ansys
Transfer_ansys (subject)

