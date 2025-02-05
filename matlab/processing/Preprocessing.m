% 1. Preprocessing after running PC-MRI
clear; close all;

% Choose subject
subject = "s101";
session = 'before';
DNS.case = "c2"; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

% full ansys folder path
DNS.ansys_path = "C:/Users/guill/Documents/chiari/computations/ansys";

DNS.TUI_path = fullfile(cas.diransys_in, DNS.case);

% ansys working folder
DNS.path_out_report = fullfile(cas.diransys, cas.subj+"_files", "dp0", "FLTG", "Fluent", DNS.case+"_variables.out");


DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
DNS.slices.locations = [cas.locations(1:end-1), "bottom", "FM-25", "top"]';
% DNS.locz = [dat_PC.locz{1:end}, dat_PC.locz{1}+2.5, NaN];
DNS.mesh_size = 0.001;
DNS.cycles = 3;
DNS.delta_h_FM = 25;
DNS.iterations_ts = 20;
DNS.ts_cycle = 100;


addpath('Functions/');
addpath('Functions/Others/')

save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')

%% 2. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(dat_PC, cas);

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(dat_PC, cas, 30, DNS.ts_cycle);

%% 4. Create CSV files with velocity field information for top and bottom locations
velocity_profiles (dat_PC, cas, DNS.ts_cycle);

%% 5. TUIs to be loaded in ANSYS
if ~isfolder(DNS.TUI_path)
    mkdir(DNS.TUI_path);
end

create_mesh_journal(cas, DNS);

% setup simulation 
setup_case_TUI(DNS);

% Create pcmri surfaces in ansys and surface
create_surfaces_journal_TUI(dat_PC, cas, DNS.TUI_path);

% Reports
reports_journal_TUI(cas, DNS);

% run simulation
run_simulation_TUI(dat_PC, cas, DNS);