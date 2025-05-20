% 1. Preprocessing after running PC-MRI
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c: geometry bounded with 2 pcMRI planes. 
% c0/c1 for zero pressure top and bottom flow rate/velocity
% c2 for two inlet velocities; continuity: normal velocity tonsils 

case_name = {"c2"};      % Array with the kind of simulations to do
mesh_size = [0.0002];    % Array with the different mesh sizes to be simulated

ts_cycle = 100;     % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3;         % cyles to be computed
n_cores = 12;       % number of processors simulation

boundary_inlet = "top"; % in the case of pressure outlet (case 0/1)

check_valid_case(case_name) 

[cas, dat_PC] = check_subject_initialization(subject, ts_cycle);

DNS_cases = create_DNS_cases (case_name, mesh_size, cas, cycles, iterations_ts, ts_cycle);

% run fluent-meshing to create meshes and corresponding .cas files
cases_ready = GUI_create_mesh(cas, mesh_size);

% visualize output ANSYS console
visualize_console = 1;

if cases_ready == true
    answer = questdlg('Run ANSYS simulation?', 'Confirmation', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        disp('Running ANSYS simulation...');   
        run_ANSYS_simulations (cas, dat_PC, DNS_cases, n_cores, boundary_inlet, visualize_console)
    else
    end
end


%% Auxiliary functions 

function check_valid_case(case_names)
    valid_cases = ["c0","c1","c2","cn0","cn1","cn2"];

    % Loop through each case to see if its valid
    for i = 1:length(case_names)
        this_case = string(case_names{i});
        if ~ismember(this_case, valid_cases)
            error("Invalid case name: '%s'. Must be one of: %s", ...
                  this_case, strjoin(valid_cases, ", "));
        end
    end
end

function [cas, dat_PC] = check_subject_initialization(subject, ts_cycle, repeat_initialization)
    if nargin < 3
        repeat_initialization = 0;
    end

    % load data
    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "03-apply_roi_compute_Q.mat");
    load(mri_data_path, 'cas', 'dat_PC');
    
    % auxiliary file used to see if ANSYS data is up to date
    file_to_compare = fullfile(cas.diransys_in, "flow-rates", "Q_bottom.txt"); 

    % Create ansys inputs if needed or if forced by repeat_initialization
    if repeat_initialization || exist(file_to_compare, 'file') == 0 || ...
            datetime(dir(mri_data_path).date) > datetime(dir(file_to_compare).date)
        disp('ansys inputs need to be created\updated, creating files...')
        create_ansys_inputs(dat_PC, cas, ts_cycle);
    else 
        disp('ansys inputs are up to date ...')
    end
end