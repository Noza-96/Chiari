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
% out: rigid transformation of pc-mri slices to adjust to segmentation
main_3_alignment_MRI(cas, false);

%% 4) PC-MRI measurements
% Define ROIs for pc-mri measurements
crop_size = 100;
[cas, dat_PC] = main_4_crop_set_roi(cas, crop_size);

%% 5) Filter and create animation
% out: apply filters to pc-mri measurements and compute velocity metrics
[cas, dat_PC] = main_5_apply_roi_compute_Q(cas, true, true, true, true, true, true);

%% 6) Registration 
% out: non-linear registration of pc-mri slices to segmentation
[cas, dat_PC] = main_6_registration(cas);

%% 7) Setup DNS cases
% out: created ANSYS inputs (e.g., flow-rates, planes, and velocity profiles)
case_name = {"c1"};   % Instructions for case_name within function 
mesh_size = 0.0002;   % Array with the different mesh sizes to be simulated
ts_cycle = 40;       % number of time steps per cycle
cycles = 1;           % cyles to be computed
iterations_ts = 20;   % iterations per time step
z_p = 0:-5:ceil(dat_PC.locz{end}*10+1); % axial locations relative to the FM to obtain spatially-averaged pressure over cardiac cycle
[cas, dat_PC, DNS_cases] = main_7_setup_DNS_cases(cas, case_name, mesh_size, ts_cycle, cycles, iterations_ts, z_p);


%% 8) Define geometry in SpaceClaim
% out: geometry of CSF space 
main_8_geometry(cas);

%% 9) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations
n_cores = 8;   % number of processors meshing
main_9_mesh(cas, case_name, mesh_size, n_cores)

%% 10) ANSYS simulations
% out: simulation reports containing velocity and pressure metrics
n_cores = 14;   % number of processors Fluent
main_10_run_simulation(cas, dat_PC, DNS_cases, n_cores);

%% 11) Post-processing
% out: Post-processed results (e.g., RMSE pc-mri, v_max, LI, ...)
[cas, dat_PC, pcmri, DNS] = main_11_postprocessing(cas, case_name, mesh_size, ts_cycle, cycles);
