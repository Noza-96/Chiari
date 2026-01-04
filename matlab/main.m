clear; close all; clc;
addpath('functions/'); addpath('functions/others/');

cas.subj = "s4";

%% 0) Check compatibility
% out: config file with paths
check_compatibility(["Slicer", "Python", "Ansys"]);

%% 1) Setup subject and extract MRI data 
% out: list DICOMs and organize into flow and anatomy 
[cas, dat_PC] = main_1_read_MRI_data(cas);

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
main_2_segmentation(cas);

%% 3) Alignment velocity measurements to segmentation
% out: rigid transformation of pc-mri slices to adjust to segmentation
main_3_alignment_MRI(cas);

%% 4) PC-MRI measurements
% Define ROIs for pc-mri measurements
crop_size = 100; % Image crop size used to define PC-MRI ROIs (def: 100)
[cas, dat_PC] = main_4_crop_set_roi(cas, crop_size);

%% 5) Apply ROIs, filter and compute flow metrics
% out: apply filters to pc-mri measurements and compute velocity metrics

opts = struct( ...
    'correct_aliasing',        true, ... % aliasing correction (def: false)
    'unwrap_periodic',         true, ... % periodic temporal unwrap (def: false)
    'smooth_spatial_outliers', true, ... % 3×3 spatial outlier removal (def: false)
    'gauss_filter',            true, ... % Gaussian spatial filter (def: false)
    'offset_vel',              true, ... % zero-mean flow correction (def: false)
    'fourier_dec',             true, ... % Fourier temporal decomposition (def: false)
    'factor_threshold',        0.2,  ... % outlier threshold × venc (def: 0.2)
    'sigma_gauss',             0.8,  ... % Gaussian sigma (def: 0.8)
    'Nt_fou',                  100,  ... % Fourier time samples (def: 100)
    'modes',                   20);      % Fourier modes (def: 20)

[cas, dat_PC] = main_5_apply_roi_compute_Q(cas, opts);

%% 6) Registration 
% out: non-linear registration of pc-mri slices to segmentation
[cas, dat_PC] = main_6_registration(cas);

%% 7) Setup DNS cases
% out: created ANSYS inputs (e.g., flow-rates, planes, and velocity profiles)

case_name     = {"c1"};        % case identifiers (def: {"c1"})
mesh_size     = 2e-4;          % minimum mesh size [m] (def: 2e-4)
ts_cycle      = 100;           % time steps per cardiac cycle (def: 100)
cycles        = 3;             % number of cardiac cycles (def: 3)
iterations_ts = 20;            % iterations per time step (def: 20)

% Axial pressure locations z_p:
% - if empty, they are automatically set inside the function as
%   z_p = 0:-5:ceil(dat_PC.locz{end}*10+1)
z_p = [];                      % axial pressure planes (def: auto)

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
% Outputs:
%   DNS.slices  : CFD-predicted velocity (v) and pressure (p) sampled at PC-MRI locations
%   DNS.out     : Flow rate (q) at selected locations, spatially averaged pressure
%                 at multiple axial positions, and longitudinal impedance
%                 between the foramen magnum (FM) and 25 mm below,
%                 computed using the bottom flow rate (q_bottom)
%   DNS.RMSE    : CFD error relative to PC-MRI, computed at each location and
%                 averaged over space, time, and space–time

[cas, dat_PC, pcmri, DNS] = main_11_postprocessing(cas, case_name, mesh_size, ts_cycle, cycles);
