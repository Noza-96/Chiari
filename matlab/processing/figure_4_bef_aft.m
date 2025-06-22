close all; clear;
subject = {"s101_b","s101_a","s101_aa"} ;
case_name = "b0t";
mesh_size = 0.0002;

fs = 14;
fan = 10;
Nt = 100;  % Last N time steps
n_cases = length(subject);

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

color_m = {red, blue, green};


mri_data_path = fullfile("../../../computations", "pc-mri", subject{1}, "mat", "04-registration.mat");
load(mri_data_path, 'cas');

% === Load one case to get locations and indices ===
[t_geom, t_sim, b_inlet] = get_type_simulation(case_name);
DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
load(data_path, 'DNS');
dp_locs = DNS.out.dp.loc;
Nloc = length(dp_locs);
ref_loc = dp_locs{end};

% === Indices of interest: first, middle, last (excluding ref) ===
idx_to_plot = [1, floor((Nloc-1)/2), Nloc-2];

% === Set up figure ===
ff=figure;
set(ff, 'Position', [200, 200, 400, 500]);  % Wider for extra tile
tiledlayout(length(idx_to_plot), 2, 'TileSpacing', 'compact', 'Padding', 'compact');

colors = lines(n_cases);
t = linspace(0,1,Nt);

for k = 1:length(idx_to_plot)
    j = idx_to_plot(k);

    for s = 1:length(subject)
        mri_data_path = fullfile("../../../computations", "pc-mri", subject{s}, "mat", "04-registration.mat");
        load(mri_data_path, 'cas');
        % Load each case
        case_i = case_name;
        [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
            continue
        end
        load(data_path, 'DNS');

        % Pressure difference with respect to last location
        dp_vals = DNS.out.dp.val;
        dp_diff = dp_vals{j}(end-Nt+1:end) - dp_vals{end}(end-Nt+1:end);
        [ZL,LI_i] = longitudinal_impedance(dp_diff, DNS.out.q_bottom(end-Nt+1:end));
        nexttile(2*k-1)
        hold on;
        plot(t, dp_diff, 'LineWidth', 1.5, 'LineStyle','-','Color', color_m{s});

        nexttile(2*k)
        hold on;
        plot(t, DNS.out.q_bottom(end-Nt+1:end)*1e6, 'Color', color_m{s}, 'LineWidth', 1.5, 'LineStyle','-');
    end
    nexttile(2*k-1)
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
    xticks(0:0.2:1)
    if k == length(idx_to_plot)
        xlabel('Cardiac cycle $(t/T)$', 'Interpreter', 'latex', 'FontSize',fs)
    end
    if k == 1
    title("$\Delta p \, [{\rm Pa}]$", 'Interpreter', 'latex', 'FontSize',fs);
    end
    ylabel(dp_locs{j}{1}+ " - " +ref_loc{1}, 'Interpreter', 'latex', 'FontSize', fs);
    grid off;
    % if k == 1
    %     legend('show', 'FontSize', 9, 'Location', 'best');
    % end
    yline(0,':',LineWidth=1)
    ylim([-8,14])
    % yticks(-20:1:20)
    box on

    nexttile(2*k)
    % Customize plot appearance
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);
    if k == length(idx_to_plot)
        xlabel('Cardiac cycle $(t/T)$', 'Interpreter', 'latex', 'FontSize',fs)
    end
    if k == 1
    title("$Q \, [{\rm ml/s} ]$", 'Interpreter', 'latex', 'FontSize', fs);
    end
    % xlim([1, 8]);
    xticks(0:0.25:1)
    ylim([-2,1.5])
    yline(0,':',LineWidth=1)
    % ylim([0, 100]);
    box on

end

print(gcf, fullfile(pwd,'Figures', 'fig_4'), '-depsc','-vector');
