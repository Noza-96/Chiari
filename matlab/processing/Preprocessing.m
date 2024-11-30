% 1. Preprocessing after running PC-MRI
clear; close all;

% Choose subject
subject = "s101";

% Define MRI data path
MRI_path = fullfile("..", "2. Flow_rate_MRI", "dat", subject, "flow", "20240606am-card", "mat", "*");

% Load data
[cas, dat_PC] = load_data(subject, MRI_path);

%% 2. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(subject, dat_PC, cas);

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(subject, dat_PC, 30, 1);

%% 4. Transform MRI measurements for ANSYS inlet velocity profile - Variable (Here we change sign of velocity)
MRI_to_ansys_inlet_velocity(subject, dat_PC, 0);

%% 5. Generate journal file for variable velocity ANSYS simulation
velocity_inlet_journal(subject);

%% 6. Transfer data into ansys
Transfer_ansys (subject)

