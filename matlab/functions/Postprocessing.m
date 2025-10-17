%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clc; clear; close all;
addpath('Functions/');
addpath('Functions/Others/')
addpath('Functions/ligaments-paper/')

% Choose subject
subject = "s101_b";

% c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
% case_name = { "c2", "c1t", "c1b","c0t"}; 
case_name = {"c0t", "c3", "cl3_v1"};
mesh_size = [0.0002];

% read ansys reports and save solution in .mat file
[cas, dat_PC, pcmri, DNS] = read_ansys_reports(subject, case_name, mesh_size);

%% Animation comparison PC-MRI with Ansys solution -- Animation
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas', 'dat_PC');
case_name ={"c3"};
mesh_size = [0.0002];
warning('off', 'all');
comparison_results(cas, case_name, mesh_size)
warning('on', 'all');

%% snapshots - bcs
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 70, 80];
snapshot_results(cas, subject, case_name, mesh_size, selected_times)
warning('on', 'all');

%% pressure - bcs
close all; clear;
subject = "s101_b";
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = [0.0002];
[ZL,LI] = fig_pressure(subject, case_name, mesh_size);

%% snapshots - anatomy
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c3", "cn3_v1", "cl3_v1",  "cnl3_v1"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 70, 80];
snapshot_results(cas, subject, case_name, mesh_size, selected_times)
warning('on', 'all');

%% pressure - anatomy
close all; clear;
subject = "s101_b";
case_name ={"c3", "cn3_v1", "cl3_v1",  "cnl3_v1"};
mesh_size = [0.0002];
[ZL,LI] = fig_pressure(subject, case_name, mesh_size);

%% figure 9 - anterior-posterior flow 
figure_9;

%% figure 10 - anterior-posterior pressure 
figure_10;