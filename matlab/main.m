% Add functions
clear; close all; clc;
addpath('pc-MRI/');
addpath('processing/');
addpath('processing/Functions/');
addpath('processing/Functions/Others/');

cas.subj = "s5";


%% 0) Check compatibility
% out: config file with paths
check_compatibility(["Slicer", "ANSYS"]);

fprintf('\n--- Processing subject: %s ---\n\n', cas.subj);

%% 1) Setup subject and extract MRI data 
% out: list DICOMs and organize into flow and anatomy 
[cas, dat_PC] = read_MRI_data(cas);

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
run_segmentation(cas);

%% 3) Alignment velocity measurements to segmentation
% out: translation velocity DICOMs to adjucts to segmentation
alignment_MRI(cas);
%% 4) PC-MRI measurements
crop_size = 100;
[cas,dat_PC] = main_2_crop_set_roi(cas,dat_PC, crop_size);

%% 
correct_aliasing = true; % wrap in time - aliasing correction
unwrap_periodic = true; % allow for periodic wraping
smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
gauss_filter = true; % apply gauss filter
offset_vel = true;  % correction offset 
[cas,dat_PC] = main_3_apply_roi_compute_Q(cas,dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel);

%% 6) Define geometry in SpaceClaim
% out: computational domain

%% 6) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations

%% 5) ANSYS simulations
% out: 

%% 6) Post-processing
% out: computational domain