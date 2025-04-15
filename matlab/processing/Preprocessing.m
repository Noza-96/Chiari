% 1. Preprocessing after running PC-MRI
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c: geometry bounded with 2 pcMRI planes. 
% c0/c1 for zero pressure top and bottom flow rate/velocity
% c2 for two inlet velocities; continuity: normal velocity tonsils 

case_name = {"c2"}; % Array with the kind of simulations to do
mesh_size = [0.0005];    % Array with the different mesh sizes to be simulated

ts_cycle = 100;     % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3;         % cyles to be computed
delta_h_FM = 25;    % mm from the FM to measure LI
n_cores = 10;       % number of processors simulation

check_valid_case(case_name) 

[cas, dat_PC] = check_subject_initialization(subject);

DNS_cases = create_DNS_cases (case_name, mesh_size, cas, cycles, delta_h_FM, iterations_ts, ts_cycle);

% journal to be used for creating all meshes and corresponding .cas files
cases_ready = GUI_create_mesh(cas, dat_PC, DNS_cases);

% visualize output ANSYS console
visualize_console = 1;

if cases_ready == true
    answer = questdlg('Run ANSYS simulation?', 'Confirmation', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        disp('Running ANSYS simulation...');   
        run_ANSYS_simulations (cas, dat_PC, DNS_cases, n_cores, visualize_console)
    else
    end
end


%% Auxiliary functions 

function check_valid_case(case_names)
    valid_cases = ["c0","c1","c2","b0","b1","cn0","cn1","cn2","bn0","bn1"];

    % Loop through each case to see if its valid
    for i = 1:length(case_names)
        this_case = string(case_names{i});
        if ~ismember(this_case, valid_cases)
            error("Invalid case name: '%s'. Must be one of: %s", ...
                  this_case, strjoin(valid_cases, ", "));
        end
    end
end

function [cas, dat_PC] = check_subject_initialization (subject)
    % load data
    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat","03-apply_roi_compute_Q.mat");
    load(mri_data_path, 'cas','dat_PC');
    % auxiliary file used to see if ANSYS data is up to date
    file_to_compare = fullfile(cas.diransys_in, "flow-rates", "Q_bottom.txt"); 
    
    % Create ansys inputs and pcmri.mat
    if exist(file_to_compare,'file') == 0 || datetime(dir(mri_data_path).date) > datetime(dir(file_to_compare).date)
        disp('ansys inputs need to be created\updated, creating files...')
        create_ansys_inputs (dat_PC, cas, ts_cycle);
    else 
        disp('ansys inputs are up to date ...')
    end
end