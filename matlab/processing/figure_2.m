function figure_2(subject, case_name, mesh_size)
    line_sty = [    "-", "-", "--", "-", "-"];
    
    fs = 14;
    fan = 10;
    rows = 3;
    
    
    % Load MRI data
    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
    load(mri_data_path, 'cas');
    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
    
    t = linspace(0, 1, pcmri.Nt);
    n_cases = length(case_name);
    colors = lines(n_cases);  % Unique colors per case
    
    % === First pass: determine max RMSE for each location ===
    max_y = zeros(1, pcmri.Ndat);  % max RMSE per location
    RMSE_ave_all = zeros(pcmri.Ndat, n_cases);  % [location × case]
    exist_case = ones(1, n_cases);
    
    for i = 1:n_cases
        case_i = case_name{i};
        [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    
        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
            exist_case(i) = 0;
            continue
        end
    
        load(data_path, 'DNS');
    
        for k = 1:pcmri.Ndat
            if ~isempty(DNS.RMSE{k})
                max_y(k) = max([max_y(k), max(DNS.RMSE{k}, [], 'omitnan')]);
            end
            if isfield(DNS, 'RMSE_ave') && ~isempty(DNS.RMSE_ave)
                RMSE_ave_all(k, i) = DNS.RMSE_ave{k};
            end
        end
    end
    
    % === Plotting ===
    ff = figure;
    set(ff, 'Position', [200, 200, 300, 470]);  % Wider for extra tile
    tiledlayout(pcmri.Ndat, rows, "TileSpacing", "tight", "Padding", "compact")
    for k = 1:pcmri.Ndat
        % === Main RMSE plot (columns 1 to 3) ===
        nexttile(1+(k-1)*rows, [1, rows - 1])  % span 3 columns
        for i = 1:n_cases
            if exist_case(i)
            case_i = case_name{i};
            [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
            DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
            data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
            load(data_path, 'DNS');
    
            plot(t, DNS.RMSE{k}, 'LineStyle',line_sty(i),'LineWidth', 1.5, 'Color', colors(i, :));
            hold on
            end
        end
        set(gca, 'LineWidth', 0.5, 'TickLength', [0.01 0.01], 'FontSize', fan);
        grid on
        set(gca, 'XGrid', 'off', 'YGrid', 'on')
    
        ylim([0, max(max_y(k)*1.1, 0.01)])
        % ylim([0, 0.015])
        % ylabel(pcmri.locations{k}, 'Interpreter', 'latex', 'FontSize',fs)
        xticks(0:0.2:1)
        yticks(0:0.005:0.1)
        
        if k == 1
            title('$\langle {\rm RMSE} \rangle$', 'Interpreter', 'latex', 'FontSize',fs)
        end
    
        if k == pcmri.Ndat
            xlabel('Cardiac cycle $(t/T)$', 'Interpreter', 'latex', 'FontSize',fs)
        else
            xticklabels([])
        end
        
        % === Time-averaged RMSE bar plot (4th column) ===
        nexttile((k)*rows)  % next column tile on the same row
        bar(RMSE_ave_all(k, :), 'FaceColor', 'flat');
        for i = 1:n_cases
            bar_color = colors(i, :);
            h = findobj(gca, 'Type', 'Bar');
            h.CData(i, :) = bar_color;
        end
        set(gca, 'LineWidth', 0.5, 'TickLength', [0.01 0.01], 'FontSize', fan);
        if k == 1
            title('$\langle \overline{{\rm RMSE}} \rangle$ ', 'Interpreter', 'latex', 'FontSize',fs)
        elseif k == pcmri.Ndat
            % xlabel('Configuration', 'Interpreter', 'latex', 'FontSize',fs)
        end
        ylim([0, max(max_y(k))*1.1])
        % ylim([0, 0.015])
        yticks(0:0.0025:0.1)
        xticklabels([])
        yticklabels([])
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);
        box on
        grid on
        set(gca, 'XGrid', 'off', 'YGrid', 'on')
    end
    
    % Legend (added once outside the loop)
    % lgd = legend(case_name, 'Location', 'bestoutside');
    % lgd.Layout.Tile = 'east';
    
    print(gcf, fullfile(pwd,'Figures', subject+'_fig_2'), '-depsc','-vector');
end
