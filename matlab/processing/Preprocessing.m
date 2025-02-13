% 1. Preprocessing after running PC-MRI
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101";
session = 'before';

case_name = "c1"; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.0005,0.0002];

ts_cycle = 100;     % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3;         % cyles to be computed
delta_h_FM = 25;    % mm from the FM to measure LI
n_cores = 10;       % number of processors simulation
ansys_path = "C:/Users/guill/Documents/chiari/computations/ansys";

% Create DNS.mat files with the information
[DNS_cases, cas, dat_PC]  = setup_case(subject, session, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM, ansys_path);


% journal to be used for creating all meshes and corresponding .cas files
cases_ready = create_mesh_journal(cas, DNS_cases);

if cases_ready == true
    answer = questdlg('Run ANSYS simulation?', 'Confirmation', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        disp('Running ANSYS simulation...');
        run_ANSYS_simulations (cas, dat_PC, DNS_cases, n_cores)
    else
    end
end