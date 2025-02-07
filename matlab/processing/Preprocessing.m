% 1. Preprocessing after running PC-MRI
clear; close all;
addpath('Functions/');
addpath('Functions/Others/')


% Choose subject
subject = "s101";
session = 'before';

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"), 'cas','dat_PC');

case_name = {"c1","c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.001,0.002]; %Vector containing different mesh sizes to be computed
ts_cycle = 100; % number of time steps per cycle
iterations_ts = 20; % iterations per time step
cycles = 3; % cyles to be computed
delta_h_FM = 25; % mm from the FM to measure LI

% Create .mat files with the information
DNS_cases = setup_case(cas, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM);

% journal to be used for creating all meshes and corresponding .cas files
create_mesh_journal(cas, DNS_cases);
        
% setup simulation 
setup_case_TUI(DNS);
        
% Create pcmri surfaces in ansys and surface
create_surfaces_journal_TUI(dat_PC, cas, DNS.TUI_path);
        
% Reports
reports_journal_TUI(cas, DNS);
        
% run simulation
run_simulation_TUI(dat_PC, cas, DNS);

%% 2. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(dat_PC, cas);

%% 3. Create Fourier flow rate data for ANSYS input - Uniform
Q0_ansys(dat_PC, cas, 30, DNS.ts_cycle);

%% 4. Create CSV files with velocity field information for top and bottom locations
velocity_profiles (dat_PC, cas, DNS.ts_cycle);


function DNS_cases = setup_case(cas, case_name, mesh_size, ts_cycle, iterations_ts, cycles, delta_h_FM)

DNS_cases = cell(length(case_name),length(mesh_size));

    for i = 1:length(case_name)     
        for j = 1:length(mesh_size)
            case_i = case_name {i};
            mesh_j = mesh_size (j);

            DNS.mesh_size = mesh_j;
            DNS.case = case_i+"_dx"+formatDecimal(DNS.mesh_size); 
            
            % full ansys folder path
            DNS.ansys_path = "C:/Users/guill/Documents/chiari/computations/ansys";
            
            DNS.TUI_path = fullfile(cas.diransys_in, DNS.case);
            
            % ansys working folder
            DNS.path_out_report = fullfile(cas.diransys, cas.subj+"_files", "dp0", "FLTG", "Fluent", DNS.case+"_variables.out");
            
            
            DNS.fields = {'pressure', 'x-velocity', 'y-velocity', 'z-velocity'};
            DNS.slices.locations = [cas.locations(1:end-1), "bottom", "FM-25", "top"]';
            DNS.cycles = cycles;
            DNS.delta_h_FM = delta_h_FM;
            DNS.iterations_ts = iterations_ts;
            DNS.ts_cycle = ts_cycle;
            
            DNS_cases{i,j} = DNS.case;
            % TUIs to be loaded in ANSYS
            if ~isfolder(DNS.TUI_path)
                mkdir(DNS.TUI_path);
            end
            save(fullfile(cas.dirmat,"DNS_"+DNS.case+".mat"),'DNS')
            clear DNS
        end
    end
end

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