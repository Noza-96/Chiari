% 1. Preprocessing after running PC-MRI
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')


% Choose subject
subject = "s101";
session = 'before';

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"), 'cas','dat_PC');

case_name = "c1"; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.0005,0.0002];

ts_cycle = 100;     % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3;         % cyles to be computed
delta_h_FM = 25;    % mm from the FM to measure LI
n_cores = 10;       % number of processors simulation
ansys_path = "C:/Users/guill/Documents/chiari/computations/ansys";

% Create .mat files with the information
DNS_cases = setup_case(cas, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM, ansys_path);

% journal to be used for creating all meshes and corresponding .cas files
create_mesh_journal(cas, DNS_cases);
  
% run ansys simulation through terminal

for k = 1:length(DNS_cases)

    tic; % Start timing

    load(fullfile(cas.dirmat, "DNS_" + DNS_cases{k} + ".mat"), 'DNS');

    % Check if the case file exists
    if ~isfile(fullfile(cas.diransys_in, DNS.case + "_0.cas.gz"))
        fprintf('Error: Case file %s not found.\n', DNS_cases{k});
        continue; % Skip to the next iteration
    end

    % create ansys journal
    create_journal(dat_PC, cas, DNS)

    % run ansys journal through terminal
    fluent_cmd = "fluent 3ddp -t"+n_cores+" -g -i """+fullfile(DNS.ansys_path,DNS.subject,"inputs",DNS_cases{k}+".jou")+"""";
    system(fluent_cmd + " > nul"); % run with "> nul" to not print terminal

    elapsed_time = toc; % Stop timing
    delete('fluent*') % delete files created during the sumilation
    movefile(DNS_cases{k}+"_variables.out", fullfile(cas.diransys_out,DNS_cases{k},DNS_cases{k}+"_report.out"))
    fprintf("%s completed in %.2f seconds.\n", DNS_cases{k}, elapsed_time);
    DNS.time = elapsed_time;
    save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
    clear DNS
    
end

%% Run ANSYS
n_cores = 10;

for k = 1:length(DNS_cases)
    tic; % Start timing

    load(fullfile(cas.dirmat, "DNS_" + DNS_cases{k} + ".mat"), 'DNS');
    fluent_cmd = "fluent 3ddp -t"+n_cores+" -g -i """+fullfile(DNS.ansys_path,DNS.subject,"inputs",DNS_cases{k}+".jou")+"""";
    system(fluent_cmd + " > nul");

    elapsed_time = toc; % Stop timing
    delete('fluent*')
    movefile(DNS_cases{k}+"_variables.out", fullfile(cas.diransys_out,DNS_cases{k},DNS_cases{k}+"_report.out"))
    fprintf("%s completed in %.2f seconds.\n", DNS_cases{k}, elapsed_time);
    DNS.time = elapsed_time;
    save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
    clear DNS
end
%% 2. Create CSV files with velocity field information and pcmri.mat
velocity_profiles (dat_PC, cas, ts_cycle);

%% 3. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(dat_PC, cas, ts_cycle);


% pcmri_velocity(cas, pcmri)

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(dat_PC, cas, 30, ts_cycle);




function formattedStr = formatDecimal(num)
    % Convert number to string without scientific notation
    strNum = sprintf('%.10f', num);  
    strNum(strNum == '.') = ''; % Remove decimal point

    % Remove trailing zeros
    strNum = regexprep(strNum, '0+$', '');

    % Ensure at least one leading zero remains
    if isempty(strNum)
        formattedStr = '0';
    else
        formattedStr = strNum;
    end
end

function create_journal(dat_PC, cas, DNS)
    fileID = fopen(cas.diransys_in + "/" + DNS.case + ".jou", 'w');
    % setup simulation 
    setup_case_TUI(DNS, fileID);
            
    % Create pcmri surfaces in ansys and surface
    create_surfaces_journal_TUI(dat_PC, cas, DNS, fileID);
            
    % Reports
    reports_journal_TUI(cas, DNS, fileID);
            
    % run simulation
    run_simulation_TUI(dat_PC, cas, DNS, fileID);
end