% 1. Preprocessing after running PC-MRI
clear; close all;

% Choose subject
subject = "s101";
session = 'before';


% Define MRI data path
data_path = fullfile("..", "flow-rate-MRI", "dat", subject, "flow", session);

% Load data
[cas, dat_PC] = load_data(subject, fullfile(data_path, "mat", "*"));

%% 2. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(subject, data_path, dat_PC, cas);

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(subject, dat_PC, 30, 1);

%% 4. Transform MRI measurements for ANSYS inlet velocity profile - Variable (Here we change sign of velocity)
MRI_to_ansys_inlet_velocity(subject, dat_PC, 0);

%% 5. Generate journal file for variable velocity ANSYS simulation
velocity_inlet_journal(subject);

%% 6. Transfer data into ansys
Transfer_ansys (subject)

