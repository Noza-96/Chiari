close all; clear;

subject = {"s101_b", "s101_a", "s101_aa"};
case_name = "b0t";
mesh_size = 0.0002;
fs = 16;
fan = 14;
Nt = 100;
n_cases = length(subject);

% Colors
red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];
color_m = {red, blue, green};

% Load one case to get location indices
mri_data_path = fullfile("../../../computations", "pc-mri", subject{1}, "mat", "04-registration.mat");
load(mri_data_path, 'cas');
[t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name);
DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
load(data_path, 'DNS');
dp_locs = DNS.out.dp.loc;
ref_loc = dp_locs{1};

% Locations to plot
idx_to_plot = [10, 20, 30];

% Create figure
ff = figure;
set(ff, 'Position', [200, 200, 520, 450]);
tiledlayout(length(idx_to_plot), 2, 'TileSpacing', 'compact', 'Padding', 'compact');
t = linspace(0, 1, Nt);
max_ZL = zeros(1,length(idx_to_plot));

for k = 1:length(idx_to_plot)
    j = idx_to_plot(k);

    for s = 1:length(subject)
        mri_data_path = fullfile("../../../computations", "pc-mri", subject{s}, "mat", "04-registration.mat");
        load(mri_data_path, 'cas');
        [t_geom, t_sim, b_inlet] = get_type_simulation(case_name);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");

        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', data_path);
            continue
        end

        load(data_path, 'DNS');
        dp_vals = DNS.out.dp.val;
        q_vals = DNS.out.q_bottom;

        % Compute pressure difference and impedance
        dp_diff = -(dp_vals{j+1}(end-Nt+1:end) - dp_vals{1}(end-Nt+1:end));
        [ZL, ~] = longitudinal_impedance(dp_diff, q_vals(end-Nt+1:end));

        % === Pressure plot
        nexttile((k-1)*2 + 1)
        hold on;
        plot(t, dp_diff, 'LineWidth', 1.5, 'Color', color_m{s});

        % === Impedance plot with shadow
        nexttile((k-1)*2 + 2)
        hold on;
        Nf = length(ZL);
        f = 1:8;  % adjust to your sampling rate if needed

        % fill([f fliplr(f)], [zeros(1, Nf) fliplr(ZL')], ...
        %     color_m{s}, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        plot(f, ZL, 'LineWidth', 1.5, 'Color', color_m{s});
        ZL(end)
        max_ZL(k)= max(max_ZL(k),ZL(end));
    end

    % Customize pressure subplot
    nexttile((k-1)*2 + 1)
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
    xticks(0:0.2:1)
    if k == length(idx_to_plot)
        xlabel('Cardiac cycle $(t/T)$', 'Interpreter', 'latex', 'FontSize', fs);
    else
        xticklabels([]);
    end
    if k == 1
        title('Pressure jump', 'FontSize', fs, 'FontWeight', 'normal');
    end
    ylabel("$\overline{\Delta p} \, [{\rm Pa}] $", 'Interpreter', 'latex', 'FontSize', fs);
    % ylabel("$\overline{\Delta p}(z=" + num2str(idx_to_plot(k)/10) + "\,{\rm cm})$", 'Interpreter', 'latex', 'FontSize', fs);
    yline(0, ':', 'LineWidth', 1);
    ylim([-5, 8])
    box on

    % Customize impedance subplot
    nexttile((k-1)*2 + 2)
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
    if k == length(idx_to_plot)
        xlabel('$f\,[{\rm Hz}]$', 'Interpreter', 'latex', 'FontSize', fs);
    else
        xticklabels([]);
    end
    if k == 1
        title('Longitudinal impedance', 'FontSize', fs, 'FontWeight', 'normal');
    end
    ylabel('$Z_L\,[{\rm dyn{\cdot}s}/{\rm cm}^5]$', 'Interpreter', 'latex', 'FontSize', fs);
    xlim([1, 8])
    % ylim([0, ceil(max_ZL(k)/10)*10])
    ylim([0, 110])
    box on
end
if ~exist('Figures', 'dir'); mkdir('Figures'); end
print(gcf, fullfile('Figures', 'fig_4.eps'), '-depsc', '-painters');