%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clear; close all;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101";
session = 'before';

%c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
case_name = {"c2","c1"}; 
mesh_size = [0.0302,0.2];


case_reports = case_name+"_dx"+formatDecimal(mesh_size)';

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

% read ansys reports and save solution in .mat file
read_ansys_reports(cas, dat_PC, case_reports) 

%% 
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
load(fullfile(cas.dirmat, "DNS_"+case_report+".mat"), 'DNS');
%% 2. Create 3D animations with velocity results into spinal canal geometry
animation_3D(cas, dat_PC, DNS)

%% 3. Longitudinal impedance - Pressure drop and Flow rate
longitudinal_impedance(cas, DNS)

%% 3. Calculate flow rate from PC-MRI measurements and visualize locations
MRI_locations(dat_PC, cas, ts_cycle);

%% 4. Comparison PC-MRI with Ansys solution -- Animation
case_name = {"c1", "c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.0002];
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');

comparison_results(cas, pcmri, case_name{1}+"_dx"+formatDecimal(mesh_size(1)), case_name{2}+"_dx"+formatDecimal(mesh_size(1)))

%% flow rates 
close all
locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);

case_name = {"c1","c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.0002];
case_report = case_name+"_dx"+formatDecimal(mesh_size);

figure

set(gcf, 'Position', [200, 200, 300, 300]);
t1 = tiledlayout(2,1);
for k = 1:2

    load(fullfile(cas.dirmat, "DNS_"+case_report{k}+".mat"), 'DNS');
    nexttile
    flow_rate(DNS.out.u_max(end-99:end)*100, 0)
    ylim([0,max(DNS.out.u_max(end-99:end)*100)*1.1])
    ylabel(case_name{k}+" DNS", 'Interpreter','latex', FontSize=12)
    if k == 1
    title("$u_{\rm max} \, [{\rm cm/s}]$", 'Interpreter','latex', FontSize=14)
    end
    xlabel([])
    xticks(0:0.2:1)
end
xlabel("$t/T$", 'Interpreter','latex', FontSize=12)
saveas(gcf, fullfile(cas.dirfig, "umax_DNS_"+DNS.case), 'png');


figure
set(gcf, 'Position', [200, 200, 300, 600]);
t2 = tiledlayout(4,1);

for k = 1:dat_PC.Ndat
    nexttile
    U = pcmri.u_normal{k}*100;
    [~,ii] = max(abs(U));
    % Create row indices (1,2,...,100) for column selection
    row_idx = 1:size(U, 2); % 1:100
    selected_values = U(sub2ind(size(U), ii, row_idx)); % Extract values
    
    flow_rate(selected_values, 0)
    ylim([min(U(:)) * 1.1, max(U(:)) * 1.1])
    % ylim([0, 15]);
    ylabel(locations{k}, 'Interpreter','latex', FontSize=12)
    if k == 1
    title("$u_{\rm max} \, [{\rm cm/s}]$", 'Interpreter','latex', FontSize=14)
    end
    xlabel([])
    xticks(0:0.2:1)
end
xlabel("$t/T$", 'Interpreter','latex', FontSize=12)
saveas(gcf, fullfile(cas.dirfig, "u_max_mri"), 'png');
%%

case_name = {"c1","c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = [0.0002];
case_report = case_name+"_dx"+formatDecimal(mesh_size);

for k = 1:2
    load(fullfile(cas.dirmat, "DNS_"+case_report{k}+".mat"), 'DNS');
    figure
    set(gcf, 'Position', [200, 200, 300, 300]);
    tiledlayout(2,1, "TileSpacing","compact","Padding","loose")
    nexttile
    flow_rate(DNS.out.dp)
    ylabel("$\langle p_{\rm FM}\rangle_x-\langle p_{\rm 25}\rangle_x \, [{\rm Pa}]$", 'Interpreter','latex', FontSize=11)
    xlabel([])
    xticklabels([])

    nexttile
    flow_rate(DNS.out.q_bottom*1e6)
    ylabel("$Q_{bottom} \, [{\rm ml/s}]$", 'Interpreter','latex', FontSize=11)

    saveas(gcf, fullfile(cas.dirfig, "dp_25_"+DNS.case), 'png');
end
%% 
figure
set(gcf, 'Position', [200, 200, 300, 600]);
tiledlayout(dat_PC.Ndat-1,1, "TileSpacing","tight","Padding","tight")
for j = 1:dat_PC.Ndat-1
nexttile
flow_rate(mean(DNS.slices.p{1},1)-mean(DNS.slices.p{1+j},1), 0)
ylabel("$\langle p_{\rm FM}\rangle_x-\langle p_{\rm "+locations{1+j}+"}\rangle_x \, [{\rm Pa}]$", 'Interpreter','latex', FontSize=12)
if j<dat_PC.Ndat-1
    xlabel([])
end
end
set(gcf, 'Color', 'w')
saveas(gcf, fullfile(cas.dirfig, "phase_pressure_"+DNS.case), 'png');



%% Create animations ANSYS simulations - uniform velocity field

