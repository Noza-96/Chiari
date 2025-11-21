% Add functions
clear; close all; clc;
addpath('functions/');
addpath('functions/others/');

cas.subj = "s000";

%% 0) Check compatibility
% out: config file with paths
check_compatibility(["Slicer", "Python", "Ansys"]);

%% 1) Setup subject and extract MRI data 
% out: list DICOMs and organize into flow and anatomy 

[cas, dat_PC] = read_MRI_data(cas);

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
run_segmentation(cas, false);

%% 3) Alignment velocity measurements to segmentation
% out: translation velocity DICOMs to adjucts to segmentation
alignment_MRI(cas, false);

%% 4) PC-MRI measurements
[cas, dat_PC] = main_2_crop_set_roi(cas, 100);

%% 5) Filter and create animation
[cas, dat_PC] = main_3_apply_roi_compute_Q(cas, true, true, true, true, true, true);

%% 6) Registration (only if segmentation exist)
[cas, dat_PC] = main_4_registration(cas);

%% 6) Define geometry in SpaceClaim
% out: computational domain

%% 6) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations

%% 5) ANSYS simulations
% out: 

%% 6) Post-processing
% out: computational domain