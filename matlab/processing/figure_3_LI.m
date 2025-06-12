subject = {"s101_b","s101_a","s101_aa"} ;
case_name = "c0t";
mesh_size = 0.0002;

fs = 14;
fan = 10;
Nt = 100;  % Last N time steps
n_cases = length(case_name);


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

ff=figure('Name', 'LI values', 'NumberTitle', 'off');
set(ff, 'Position', [200, 200, 250, 500]);  % Wider for extra tile

t = linspace(0,1,Nt);

for s = 1:length(subject)
    mri_data_path = fullfile("../../../computations", "pc-mri", subject{s}, "mat", "04-registration.mat");
    load(mri_data_path, 'cas');

    % Load each case
    case_i = case_name;
    [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
    data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    load(data_path, 'DNS');
    q = DNS.out.q_bottom(end-Nt+1:end);
    LI = zeros(1,Nloc);
    
    for k = 1:Nloc
        % Pressure difference with respect to last location
        dp_vals = DNS.out.dp.val;
        dp_diff = dp_vals{k}(end-Nt+1:end) - dp_vals{end}(end-Nt+1:end);
        [~,LI(k)] = longitudinal_impedance(dp_diff, q);
    end
    % === Plot LI values in horizontal bar chart ===
    
    
    LI_vals = LI(:);  % ensure column vector
    labels = cellfun(@(s) s{1}, dp_locs, 'UniformOutput', false);  % unwrap from string cells
    y_vals = 1:length(LI_vals);
    
    plot(LI_vals, y_vals, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', color_m{s});
    hold on
    set(gca, 'YTick', 1:length(labels), 'YTickLabel', labels, 'YDir', 'reverse');
    xlabel("${\rm LI}\, \left[{\rm dyn}/{\rm cm}^5\right]$", 'Interpreter', 'latex', 'FontSize', fs);
    title('Longitudinal Impedance',  'Interpreter', 'latex','FontSize', fs);
    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'off';
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
end
    print(gcf, fullfile(pwd,'Figures', 'fig_4_LI'), '-depsc','-vector');
