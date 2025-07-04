function fig_pressure(subject, case_name, mesh_size)


    fs = 16;
    fan = 14;
    Nt = 100;  % Last N time steps
    n_cases = length(case_name);
    
    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
    load(mri_data_path, 'cas');
    
    % === Load one case to get locations and indices ===
    case_0 = case_name{1};
    [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_0);
    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
    data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    load(data_path, 'DNS');
    DNS_0 = DNS;
    dp_locs = DNS_0.out.dp.loc;
    Nloc = length(dp_locs);
    ref_loc = dp_locs{end};
    
    j = floor((Nloc-1)/2);
    
    dp_vals = DNS.out.dp.val;
    dp_diff_0 = dp_vals{j}(end-Nt+1:end) - dp_vals{end}(end-Nt+1:end);

    
    % === Set up figure ===
    ff=figure;
    set(ff, 'Position', [200, 200, 400, 500]);  % Wider for extra tile
    tiledlayout(length(idx_to_plot), 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    colors = lines(n_cases);
    t = linspace(0,1,Nt);
    
    for i = 2:n_cases
        % Load each case
        case_i = case_name{i};
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
            continue
        end
        load(data_path, 'DNS');

        % Pressure difference with respect to last location
        dp_vals = DNS.out.dp.val;
        dp_diff = dp_vals{j}(end-Nt+1:end) - dp_vals{end}(end-Nt+1:end);
        [ZL,~] = longitudinal_impedance(dp_diff, DNS.out.q_bottom(end-Nt+1:end));
        nexttile(i-1)
        hold on;
        plot(t, dp_diff, 'LineWidth', 1.5, 'LineStyle',line_sty(i),'Color', colors(i,:), 'DisplayName', case_i);
        plot(t, dp_diff_0, 'LineWidth', 1.5, 'LineStyle',line_sty(i),'Color', colors(i,:), 'DisplayName', case_i);

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
    xlabel("$f\left[{\rm Hz}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
    end
    if k == 1
    title("$Z_L\left[{\rm dyn{\cdot}s}/{\rm cm}^5\right]$", 'Interpreter', 'latex', 'FontSize', fs);
    end
    xlim([1, 8]);
    xticks(1:10)
    % ylim([0, 100]);
    box on
    
    print(gcf, fullfile(pwd,'Figures', subject+'_fig_3'), '-depsc','-vector');
end
