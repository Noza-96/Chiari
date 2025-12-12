% Add functions
clear; close all; clc;
addpath('functions/');
addpath('functions/others/');

cas.subj = "s4";

%% 0) Check compatibility
% out: config file with paths
check_compatibility(["Slicer", "Python", "Ansys"]);

%% 1) Setup subject and extract MRI data 
% out: list DICOMs and organize into flow and anatomy 

[cas, dat_PC] = main_1_read_MRI_data(cas);

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
main_2_segmentation(cas, false);

%% 3) Alignment velocity measurements to segmentation
% out: translation velocity DICOMs to adjucts to segmentation
main_3_alignment_MRI(cas, false);

%% 4) PC-MRI measurements
[cas, dat_PC] = main_4_crop_set_roi(cas, 100);

%% 5) Filter and create animation
[cas, dat_PC] = main_5_apply_roi_compute_Q(cas, true, true, true, true, true, true);

%% 6) Registration (only if segmentation exist)
[cas, dat_PC] = main_6_registration(cas);

%% 7) Define geometry in SpaceClaim
% out: computational domain
[cas, dat_PC] = main_7_geometry(cas);

%% 8) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations
[cas, dat_PC] = main_8_setup_case_mesh(cas);

%% 9) ANSYS simulations
% out: 
[cas, dat_PC] = main_9_run_simulation(cas);

%% 10) Post-processing
% out: computational domain
[cas, dat_PC] = main_10_postprocessing(cas);
