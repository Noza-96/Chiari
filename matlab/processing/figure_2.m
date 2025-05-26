clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

subject = "s101_b";

case_name = {"c2", "c1b", "c1t"};
mesh_size = [0.0002];



    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
    load(mri_data_path, 'cas');
    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');

    t = linspace(0, 1, pcmri.Nt);
    ff = figure;
    set(ff,'Position', [200, 200, 400, 1000]);
    tiledlayout(pcmri.Ndat, 1, "TileSpacing", "compact", "Padding", "compact")
    

    colors = lines(length(case_name));  % Unique colors per case

    for i = 1:length(case_name)
        case_i = case_name{i};

        [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");

        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
            return
        end

        load(data_path, 'DNS');

        for k = 1:pcmri.Ndat
            nexttile(k)
            plot(t, DNS.RMSE{k}, 'LineWidth', 1.5, 'Color', colors(i, :))
            hold on
            grid on

            % if i == length(case_name)
            %     title(pcmri.locations{k}, 'Interpreter', 'none')
            % end

            if k == pcmri.Ndat
                xlabel('Cardiac cycle (t/T)')
            end
            if k == round(pcmri.Ndat / 2)
                ylabel('RMSE [cm/s]')
            end

            ylim([0,0.015])
        end
    end

    % Add a legend in a new figure or as overlay
    lgd = legend(case_name, 'Location', 'bestoutside');
    lgd.Layout.Tile = 'east';
