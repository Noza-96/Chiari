%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clc; clear; close all;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
% case_name = { "c2", "c1t", "c1b","c0t"}; 
case_name = {"c3"};
mesh_size = [0.0002];

% read ansys reports and save solution in .mat file
[cas, dat_PC, pcmri, DNS] = read_ansys_reports(subject, case_name, mesh_size);

%% Compare flow rates


figure
t=linspace(0,1,100);
T = dat_PC.T{end};
Q_2 = (0.006230 - 0.507068*cos(5.540728*t*T) + 0.358484*sin(5.540728*t*T) +0.099886*cos(11.081455*t*T) + 0.220855*sin(11.081455*t*T) +0.160166*cos(16.622183*t*T) - 0.045111*sin(16.622183*t*T) +0.004061*cos(22.162911*t*T) - 0.040844*sin(22.162911*t*T) +0.014446*cos(27.703638*t*T) + 0.039628*sin(27.703638*t*T) +0.056662*cos(33.244366*t*T) - 0.022429*sin(33.244366*t*T) - 0.017761*cos(38.785094*t*T) - 0.049419*sin(38.785094*t*T) - 0.024428*cos(44.325821*t*T) + 0.009302*sin(44.325821*t*T) +0.005621*cos(49.866549*t*T) + 0.003630*sin(49.866549*t*T) +0.005753*cos(55.407277*t*T) - 0.021681*sin(55.407277*t*T) - 0.015194*cos(60.948004*t*T) - 0.004667*sin(60.948004*t*T) - 0.011798*cos(66.488732*t*T) + 0.001771*sin(66.488732*t*T) - 0.003726*cos(72.029460*t*T) - 0.002699*sin(72.029460*t*T) - 0.011832*cos(77.570187*t*T) - 0.001910*sin(77.570187*t*T) - 0.006473*cos(83.110915*t*T) - 0.001615*sin(83.110915*t*T) - 0.001318*cos(88.651643*t*T) + 0.002226*sin(88.651643*t*T) - 0.002142*cos(94.192370*t*T) + 0.001036*sin(94.192370*t*T) - 0.003414*cos(99.733098*t*T) + 0.000894*sin(99.733098*t*T) +0.002786*cos(105.273826*t*T) - 0.001356*sin(105.273826*t*T) +0.002786*cos(110.814553*t*T) + 0.001356*sin(110.814553*t*T))*2;
Q_3 = (0.059839 - 0.580567*cos(5.540728*t*T) + 0.456500*sin(5.540728*t*T) +0.136410*cos(11.081455*t*T) + 0.233124*sin(11.081455*t*T) +0.177604*cos(16.622183*t*T) - 0.083403*sin(16.622183*t*T) - 0.018399*cos(22.162911*t*T) - 0.047189*sin(22.162911*t*T) +0.023178*cos(27.703638*t*T) + 0.055573*sin(27.703638*t*T) +0.071915*cos(33.244366*t*T) - 0.039511*sin(33.244366*t*T) - 0.031785*cos(38.785094*t*T) - 0.064613*sin(38.785094*t*T) - 0.024913*cos(44.325821*t*T) + 0.013857*sin(44.325821*t*T) +0.024810*cos(49.866549*t*T) + 0.007579*sin(49.866549*t*T) - 0.004526*cos(55.407277*t*T) - 0.033555*sin(55.407277*t*T) - 0.025643*cos(60.948004*t*T) - 0.006334*sin(60.948004*t*T) - 0.008328*cos(66.488732*t*T) + 0.010710*sin(66.488732*t*T) - 0.000217*cos(72.029460*t*T) + 0.003357*sin(72.029460*t*T) - 0.011682*cos(77.570187*t*T) - 0.004783*sin(77.570187*t*T) - 0.008212*cos(83.110915*t*T) + 0.008027*sin(83.110915*t*T) +0.001865*cos(88.651643*t*T) + 0.001350*sin(88.651643*t*T) - 0.005111*cos(94.192370*t*T) + 0.002421*sin(94.192370*t*T) - 0.001852*cos(99.733098*t*T) + 0.001129*sin(99.733098*t*T) +0.002078*cos(105.273826*t*T) + 0.003399*sin(105.273826*t*T) +0.002078*cos(110.814553*t*T) - 0.003399*sin(110.814553*t*T))*2; 
Q_4 = (0.112496 - 0.492666*cos(5.540728*t*T) + 0.320173*sin(5.540728*t*T) +0.133928*cos(11.081455*t*T) + 0.138644*sin(11.081455*t*T) +0.182372*cos(16.622183*t*T) - 0.053508*sin(16.622183*t*T) - 0.001575*cos(22.162911*t*T) - 0.069159*sin(22.162911*t*T) - 0.001868*cos(27.703638*t*T) + 0.049868*sin(27.703638*t*T) +0.059975*cos(33.244366*t*T) - 0.016034*sin(33.244366*t*T) - 0.004279*cos(38.785094*t*T) - 0.043748*sin(38.785094*t*T) - 0.013528*cos(44.325821*t*T) - 0.004560*sin(44.325821*t*T) +0.004798*cos(49.866549*t*T) + 0.004543*sin(49.866549*t*T) +0.000643*cos(55.407277*t*T) - 0.023009*sin(55.407277*t*T) - 0.020162*cos(60.948004*t*T) - 0.006037*sin(60.948004*t*T) - 0.008453*cos(66.488732*t*T) + 0.005449*sin(66.488732*t*T) +0.000283*cos(72.029460*t*T) - 0.005044*sin(72.029460*t*T) - 0.008470*cos(77.570187*t*T) - 0.005309*sin(77.570187*t*T) - 0.009273*cos(83.110915*t*T) + 0.001896*sin(83.110915*t*T) - 0.002764*cos(88.651643*t*T) + 0.000482*sin(88.651643*t*T) - 0.004989*cos(94.192370*t*T) + 0.001182*sin(94.192370*t*T) - 0.004826*cos(99.733098*t*T) - 0.000122*sin(99.733098*t*T) +0.000102*cos(105.273826*t*T) + 0.001769*sin(105.273826*t*T) +0.000102*cos(110.814553*t*T) - 0.001769*sin(110.814553*t*T))*2;


tiledlayout(5,1)
set(gcf, 'Position', [200, 200, 450, 1000]);
for k=1:5
    nexttile
    plot(t, DNS.out.q{k},'-', 'Color', 'b', LineWidth=1)
    hold on 
    plot(t, pcmri.q{k}, '-', 'Color', 'r', LineWidth=1)

    plot(t([40,70,80]), DNS.out.q{k}([40,70,80]),'o', 'Color', 'b', LineWidth=1)
    hold on 
    plot(t([40,70,80]), pcmri.q{k}([40,70,80]), 'o', 'Color', 'r', LineWidth=1)
    % plot(t([40,70,80]), pcmri.q{k}([40,70,80]), 'o', 'Color', 'r', LineWidth=1)

    N0 = 201;
    if k == 1
        plot(t, - DNS.out.q_top(N0:N0+99)*1e6,'--', 'Color', 'k', LineWidth=1)
        plot(t([40,70,80]), - DNS.out.q_top(N0+[40,70,80]-1)*1e6, 's', 'Color', 'k', LineWidth=1)
    elseif k == 2
        plot(t, Q_2, '--', 'Color', 'k', LineWidth=1)
    elseif k == 3
        plot(t, Q_3, '--', 'Color', 'k', LineWidth=1)
    elseif k == 4
        plot(t, Q_4, '--', 'Color', 'k', LineWidth=1)
    elseif k == 5
        plot(t, DNS.out.q_bottom(N0:N0+99)*1e6,'--', 'Color', 'k', LineWidth=1)
        plot(t([40,70,80]), DNS.out.q_bottom(N0+[40,70,80]-1)*1e6, 's', 'Color', 'k', LineWidth=1)
    end


end
% 
% pcmri.q{1}(70)
% DNS.out.q{1}(70)
% 
% pcmri.q{5}(70)- DNS.out.q{5}(70)
% 
% pcmri.q{4}(70)- DNS.out.q{4}(70)


set(gcf, 'Color', 'w')
print(gcf, fullfile(cas.dirfig,'flowrate_DNS_pcmri'), '-depsc','-vector');


%% Animation comparison PC-MRI with Ansys solution -- Animation
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas', 'dat_PC');
case_name ={ "c3", "cl3_v2","cl3_v3","cl3_v4"};
mesh_size = [0.0002];
warning('off', 'all');
comparison_results(cas, case_name, mesh_size)
warning('on', 'all');

%% snapshots characteristic times
close all; clear;
subject = "s101_aa";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 70, 80];
snapshot_results(cas, subject, case_name, mesh_size, selected_times)
warning('on', 'all');

%% pressure - bcs
close all; clear;
subject = "s101_b";
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = [0.0002];
fig_pressure(subject, case_name, mesh_size)

%% snapshots anatomy
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c3", "cl3_v6", "cl3_v1", "cl3_v2", "cl3_v3"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 71, 80];
snapshot_results(cas, subject, case_name, mesh_size, selected_times)
warning('on', 'all');

%% pressure - anatomy
close all; clear;
subject = "s101_b";
case_name ={"c3", "cl3_v7", "cl3_v6"};
mesh_size = [0.0002];
fig_pressure(subject, case_name, mesh_size)

%% Reports 
close all; clear;
subject = ["s101_b", "s101_a", "s101_aa"];
case_name = {"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = 0.0002;

for s = subject
    figure_2_b(s, case_name, mesh_size)
    figure_2(s, case_name, mesh_size)
    % figure_3_pressure(s, case_name, mesh_size)
end

% figure_3_LI

%% Anatomy-reports 
close all; clear;
subject = ["s101_b"];
case_name = {"c0t", "c3", "cl3_v2","cl3_v3","cl3_v4"};
mesh_size = 0.0002;

for s = subject
    figure_2_b(s, case_name, mesh_size)
    figure_2(s, case_name, mesh_size)
    % figure_3_pressure(s, case_name, mesh_size)
end

% figure_3_LI
%% Longitudinal Analysis 
figure_3_LI;
figure_4_bef_aft;


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

