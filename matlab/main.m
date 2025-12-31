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
crop_size = 100;
[cas, dat_PC] = main_4_crop_set_roi(cas, crop_size);

%% 5) Filter and create animation
[cas, dat_PC] = main_5_apply_roi_compute_Q(cas, true, true, true, true, true, true);

%% 6) Registration (only if segmentation exist)
[cas, dat_PC] = main_6_registration(cas);


%% 7) Setup DNS cases
% out: creted flow-rates, planes, and velocity profiles of PC-MRI
% DNS_cases contains information about the simulations to be done

case_name = {"c3"};     % Array with the kind of simulations to do
mesh_size = 0.0002;         % Array with the different mesh sizes to be simulated
ts_cycle = 100;             % number of time steps per cycle
cycles = 3;                 % cyles to be computed
iterations_ts = 20;         % iterations per time step

[cas, dat_PC, DNS_cases] = main_7_setup_DNS_cases(cas, case_name, mesh_size, ts_cycle, cycles, iterations_ts);


%% 8) Define geometry in SpaceClaim
% out: computational domain
[cas, dat_PC] = main_8_geometry(cas);

%% 9) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations
n_cores = 8;   % number of processors meshing
main_9_mesh(cas, case_name, mesh_size, n_cores)

%% 10) ANSYS simulations
% out: 
n_cores = 14;   % number of processors Fluent
[cas, dat_PC] = main_10_run_simulation(cas, DNS_cases, n_cores);

%% 11) Post-processing
% out: computational domain
[cas, dat_PC] = main_11_postprocessing(cas);
