function fig_pressure(subject, case_name, mesh_size)


    if any(cellfun(@(s) ~isempty(regexp(s, '^cl|^cn', 'once')), case_name))
        fig_ind = 4;
        conf = {"(L1)", "(L2)", "(IV)", "(V)"};
        yL = [-8,16];
    else
        fig_ind = 3;
        conf = {"(II)", "(III)", "(IV)", "(V)"};
        yL = [-8,14];
    end

    N0 = 200;

    fs = 20;
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
    j=1;
    dp_vals = DNS.out.dp.val;
    dp_diff_0 = dp_vals{j}(N0+1:N0+Nt) - dp_vals{end}(N0+1:N0+Nt);

    
    % === Set up figure ===
    ff=figure;
    set(ff, 'Position', [200, 200, 200*length(case_name), 250]);  % Wider for extra tile
    tiledlayout(1, length(case_name)-1,  'TileSpacing', 'tight', 'Padding', 'compact');
    
    colors = lines(n_cases);
    t = linspace(0,1,Nt+1);
    [dp_max_0, idx_max_0] = max(dp_diff_0);
    t_max_0 = t(idx_max_0);
    
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
        dp_diff = dp_vals{j}(N0+1:N0+Nt) - dp_vals{end}(N0+1:N0+Nt);
        % [ZL,~] = longitudinal_impedance(dp_diff, DNS.out.q_bottom(end-Nt+1:end));
        nexttile(i-1)
        hold on;
        plot(t, [dp_diff; dp_diff(1)], 'LineWidth', 2, 'LineStyle','-','Color', colors(i,:), 'DisplayName', case_i);
        plot(t, [dp_diff_0; dp_diff(1)], 'LineWidth', 2, 'LineStyle',':','Color', 'k', 'DisplayName', case_i);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
 % Annotate max value of dp_diff
    [dp_max, idx_max] = max(dp_diff);
    t_max = t(idx_max);
    plot(t_max, dp_max, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5)

    % Define label text based on subplot index
    if i == 2  % first subplot
        label_str = ['$\max(\Delta p) = ' num2str(dp_max, '%.1f') '\ \mathrm{Pa}$'];

        if fig_ind == 3
            plot(t_max_0, dp_max_0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5)
    
            % Place LaTeX annotation slightly above the peak
            text(t_max_0 - 0.05, dp_max_0-0.5, [num2str(dp_max_0, '%.1f') ' Pa'], ...
                'Interpreter', 'latex', ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', fan+1)
        end
    else  % other subplots
        label_str = [num2str(dp_max, '%.1f') ' Pa'];
        yticklabels([])
    end

    % Place LaTeX annotation slightly above the peak
        text(t_max - 0.05, dp_max-0.5, label_str, ...
            'Interpreter', 'latex', ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', fan+1)
        
        
        xticks(0:0.2:1)
        xlabel('$t/T$', 'Interpreter', 'latex', 'FontSize',fs)
        
        
        
        if i == 2
        ylabel("$\Delta p_{-"+DNS.Dz(j)+"/-"+DNS.Dz(end)+"} \, [{\rm Pa}]$", 'Interpreter', 'latex', 'FontSize',fs)
        % ylabel("$\langle \Delta p)\rangle \, [{\rm Pa}]$", 'Interpreter', 'latex', 'FontSize',fs);
        end
        title(conf{i-1}, 'Interpreter', 'latex', 'FontSize', fs);
        ylim(yL);
        grid off;
        yline(0,':',LineWidth=1)
        box on;
    end
    

    print(gcf, fullfile(pwd,'Figures', "fig_"+fig_ind+"_press"), '-depsc','-vector');
end
