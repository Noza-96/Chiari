close all; clear;

subject = "s101_b";
case_name ={"c3", "cl3_v2","cl3_v3","cl3_v4"};
mesh_size = 0.0002;

    line_sty = [    "-", "-", "-", "-", "-"];
    
    fs = 16;
    fan = 14;
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
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
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
    set(ff, 'Position', [200, 200, 450, 80*pcmri.Ndat]);  % Wider for extra tile
    tiledlayout(pcmri.Ndat-2, rows, "TileSpacing", "tight", "Padding", "compact")
    for k = 2:pcmri.Ndat-1
        % === Main RMSE plot (columns 1 to 3) ===
        1+(k-2)*rows
        nexttile(1+(k-2)*rows, [1, rows - 1])  % span 3 columns
        for i = 1:n_cases
            if exist_case(i)
            case_i = case_name{i};
            [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_i);
            DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size)+version;
            data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
            load(data_path, 'DNS');
    
            plot(t, DNS.RMSE{k}, 'LineStyle',line_sty(i),'LineWidth', 1.5, 'Color', colors(i, :));
            hold on
            end
        end
        set(gca, 'LineWidth', 0.8, 'TickLength', [0.005 0.005], 'FontSize', fan);
        grid on
        ax = gca;
        ax.YAxis.Exponent = 0;
        set(gca, 'XGrid', 'off', 'YGrid', 'on')
        box on
    
        ylim([0, max(ceil(max_y(k)*1000/5)*5/1000, 0.01)])
        % ylim([0, 0.015])
        yticks(0.005:0.005:(max(ceil(max_y(k)*1000/5)*5/1000, 0.01)-0.001))
        xticks(0:0.5:1)
        xticklabels([])
        yticklabels([])
        
        if k == 2
            title('$\langle {\rm RMSE} \rangle \, \left[{\rm cm/s}\right]$', 'Interpreter', 'latex', 'FontSize',fs)
        end
    
        if k == pcmri.Ndat-2
            % xlabel('Cardiac cycle $(t/T)$', 'Interpreter', 'latex', 'FontSize',fs)
        else
            xticklabels([])
        end
        
        % === Time-averaged RMSE bar plot (4th column) ===
        nexttile((k-1)*rows)  % next column tile on the same row
        bar(RMSE_ave_all(k, :), 'FaceColor', 'flat');
        for i = 1:n_cases
            bar_color = colors(i, :);
            h = findobj(gca, 'Type', 'Bar');
            h.CData(i, :) = bar_color;
        end
        set(gca, 'LineWidth', 0.8, 'TickLength', [0.005 0.005], 'FontSize', fan, 'YAxisLocation', 'right');
        if k == 1
            % title('$\langle \overline{{\rm RMSE}} \rangle \, \left[{\rm cm/s}\right]$ ', 'Interpreter', 'latex', 'FontSize',fs)
        elseif k == pcmri.Ndat
            % xlabel('Configuration', 'Interpreter', 'latex', 'FontSize',fs)
        end
        % ylim([0, max(max(RMSE_ave_all(k, :))*1.1, 0.005)])
        % ylim([0, 0.0075])
        ylim([0, max(ceil(max_y(k)*1000/5)*5/1000, 0.01)])

        yticks(0.005:0.005:(max(ceil(max_y(k)*1000/5)*5/1000, 0.01)-0.001))
        xticklabels([])
        if k == pcmri.Ndat
        % xticklabels({'(I)', '(II)', '(III)', '(IV)', '(V)'});
        % xlabel('Configuration', 'Interpreter', 'latex', 'FontSize',fs)
        end
        ax = gca;
        ax.YAxis.Exponent = 0;
        % yticklabels([])
        box on
        grid on
        set(gca, 'XGrid', 'off', 'YGrid', 'on')
    end
    
    % Legend (added once outside the loop)
    % lgd = legend(case_name, 'Location', 'bestoutside');
    % lgd.Layout.Tile = 'east';
    
    print(gcf, fullfile(pwd,'Figures', 'fig_4_anatomy-2'), '-depsc','-vector');
