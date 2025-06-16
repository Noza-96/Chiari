%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clc; clear; close all;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
% case_name = { "c2", "c1t", "c1b","c0t"}; 
case_name = {"c3","c0t"}; 
mesh_size = [0.0002];

% read ansys reports and save solution in .mat file
[cas, pcmri, DNS] = read_ansys_reports(subject, case_name, mesh_size);

%% Animation comparison PC-MRI with Ansys solution -- Animation
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c3","cn2","c2", "c1b", "c0t"};
mesh_size = [0.0002];
warning('off', 'all');
comparison_results(cas, case_name, mesh_size)
warning('on', 'all');

%% Reports 
subject = "s101_b";
case_name = {"c3","cn2", "c2", "c1b", "c0t"};
mesh_size = 0.0002;

for s = subject
    figure_2_b(s, case_name, mesh_size)
    figure_2(s, case_name, mesh_size)
    figure_3_pressure(s, case_name, mesh_size)
end

figure_3_LI

%% save-data
close all; clear;
addpath('Functions/');
subject = ["s101_b","s101_a", "s101_aa"];

for s = subject 
    load(fullfile("../../../computations", "pc-mri", s, "mat", "04-registration.mat"), 'dat_PC', 'cas');
    for i = 1:dat_PC.Ndat
        data_PC.U_SAS{i} = - dat_PC.U_SAS{i};
        data_PC.xyz{i} = dat_PC.pixel_coord{i};
        data_PC.Q_SAS{i} = - dat_PC.Q_SAS{i};
        data_PC.ROI_SAS{i} = dat_PC.ROI_SAS{i};
        data_PC.t{i} = dat_PC.t{i};
    end
    filepath = "/Users/noza/My Drive/Chiari Nerve Roots/" + s + "/pcmri/"+s+".mat";
    save(filepath, "data_PC", '-mat')
end
%% check fourier 

% close all; clear;
addpath('Functions/');
s = "s101_aa";
load(fullfile("../../../computations", "pc-mri", s, "mat", "04-registration.mat"), 'dat_PC', 'cas');
   
loc = 4;
% Extract relevant data
Q_orig = dat_PC.Q_SAS{loc};         % Original flow rate
t_orig = dat_PC.t{loc};             % Time vector
T = dat_PC.T{loc};                  % Period
dt = T / length(t_orig);          % Time step estimate
t_orig(end) = [];                 % Trim last point for periodicity
Q_orig(end) = [];

% Fourier components
fm = dat_PC.fou.fm{loc};            % Frequencies
am = - dat_PC.fou.am{loc};            % Complex amplitudes
a0 = 0;                           % Default DC term (not included?)

if isfield(dat_PC.fou, 'a0')
    a0 =  - dat_PC.fou.a0{loc};        % If a0 saved explicitly
end

% Reconstruct signal using Fourier series
zi = 1i;
Q_fourier = a0 + zeros(size(t_orig));
for m = 1:length(fm)
    Q_fourier = Q_fourier + am(m)*exp(zi*fm(m)*t_orig) + conj(am(m))*exp(-zi*fm(m)*t_orig);
end

% Plot comparison
figure;
plot(t_orig, - Q_orig, 'k-', 'LineWidth', 2); hold on;
plot(t_orig, Q_fourier, 'r--', 'LineWidth', 2);
xlabel('Time [s]');
ylabel('Flow rate');
legend('Original Q_{SAS}', 'Fourier reconstruction');
title('Comparison of original and Fourier-reconstructed flow rate');
grid on;

%% flow rates 
close all
locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);

case_name = {"c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
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

case_name = {"c2"}; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
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

