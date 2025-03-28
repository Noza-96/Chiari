% 1. Preprocessing after running PC-MRI
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c: geometry bounded with 2 pcMRI planes. c0/c1 for zero pressure top and bottom flow rate/velocity, c2 for two inlet velocities and permeable cord
% b: 60 mm geometry with bottom pcMRI plane. b0/b1 for zero pressure top and bottom flow rate/velocity
% cn or bn simmilar but with nerve roots. 

case_name = {"c1","c2","b1"}; % Array with the kind of simulations to do
mesh_size = [0.0005];    % Array with the different mesh sizes to be simulated


ts_cycle = 100;     % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3;         % cyles to be computed
delta_h_FM = 25;    % mm from the FM to measure LI
n_cores = 10;       % number of processors simulation

check_valid_case(case_name)

redo_initialization = 1; 

% Create DNS.mat files with the information
[DNS_cases, cas, dat_PC]  = setup_case(subject, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM, redo_initialization);


% journal to be used for creating all meshes and corresponding .cas files
cases_ready = create_mesh_journal(cas, DNS_cases);

if cases_ready == true
    answer = questdlg('Run ANSYS simulation?', 'Confirmation', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        disp('Running ANSYS simulation...');
        visualize_output = 1;
        run_ANSYS_simulations (cas, dat_PC, DNS_cases, n_cores, visualize_output)
    else
    end
end


