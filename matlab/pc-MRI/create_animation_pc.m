% Create figure with segmentation together with MRI locations
function movieVector = create_animation_pc(dat_PC, cas)

    addpath("../processing/Functions/")
    addpath('../processing/Functions/Others/')
    
    % load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');

    fs = 20;
    fan = 14;
    locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
    % z-position compared to C3C4
    locz_vals = cell2mat(dat_PC.locz);
    Dz_loc = (locz_vals(1)-locz_vals)*10;

    % Preallocate movie vector
    Ndata = dat_PC.Ndat;
    movieVector(dat_PC.Nt{1}) = struct('cdata', [], 'colormap', []);

    rows = 8;
    % Set up figure properties
    figure;
    set(gcf, 'Position', [200, 200, 1000, Ndata*240]);
    tt = tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");
    

    % Initialize variables
    Vs_SAS = zeros(1, length(dat_PC.Q_SAS));
    Vs_TONS = zeros(1, length(dat_PC.Q_TONS));
    Vs_COR = zeros(1, length(dat_PC.Q_COR));

    for n = 1:dat_PC.Nt{1}
    
        % Loop through each flow data set
        for k = 1:Ndata
            nexttile(1+(k-1)*rows, [1, 3]);
          
            create_animation_ansys(dat_PC, k, n);

            Q_SAS = -dat_PC.Q_SAS{k};  % Get flow data
            Q_TONS = -dat_PC.Q_TONS{k};  % Get flow data
            Q_COR = -dat_PC.Q_COR{k};  % Get flow data

            Nt = dat_PC.Nt{k};     % Get number of time points
            t = linspace(0, 1, dat_PC.Nt{k})*dat_PC.T{k};  % Create time vector
            t_T = linspace(0, 1, dat_PC.Nt{k});
            if k == 1
                title("$u\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            % Create a new tile for the flow rate
            nexttile(4+(k-1)*rows, [1, 3]);
            Vs_SAS(k) = 0.5 * simps(t, abs(Q_SAS), 2);  
            Vs_TONS(k) = 0.5 * simps(t, abs(Q_TONS), 2); 
            Vs_COR(k) = 0.5 * simps(t, abs(Q_COR), 2); 

            % Call the flow rate function
            plot(t_T, Q_SAS, Color='k', LineWidth=1.5)
            yline(simps(t_T, Q_SAS, 2), '--','Color', 'k', 'LineWidth', 1, 'HandleVisibility','off');            
            hold on 
            plot(t_T, Q_COR, Color='b', LineWidth=1.5)
            yline(simps(t_T, Q_COR, 2), '--','Color', 'b', 'LineWidth', 1, 'HandleVisibility','off');  
            if ~all(Q_TONS == 0)
                plot(t_T, Q_TONS, Color='r', LineWidth=1.5)
                yline(simps(t_T, Q_TONS, 2),'--', 'Color', 'r', 'LineWidth', 1, 'HandleVisibility','off')
            end
            if k == 1
                legend("$Q_{\rm CSF}$", "$Q_{\rm cord}$", "$Q_{\rm tons}$", 'interpreter', 'latex','fontsize',14)
            end
            yline(0,':', 'LineWidth', 1,'HandleVisibility','off')
            xline (t_T(n), '-', 'LineWidth', 1, 'HandleVisibility','off')
            hold off
            set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
            % Set x-tick labels conditionally
            if k < length(dat_PC.Q_SAS)
                xlabel([])
            else
                xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
            end
            xticks(0:0.5:1);

            if k == 1
                title("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            ymin = floor(min([Q_SAS(:); Q_TONS(:)]));
            ymax = ceil(max([Q_SAS(:); Q_TONS(:)]));
        
            % Set y-labels
            ylim([ymin, ymax]);
            ax = gca; % Get current axes
        end


        if n == 1
            % Plot volumes in the last tile
            nexttile(7,[Ndata, 2]);
            plot(Vs_SAS, Dz_loc, '-k', 'LineWidth', 1.5);
            hold on
            plot(Vs_SAS, Dz_loc, 'ok', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            plot(Vs_COR, Dz_loc, '-b', 'LineWidth', 1.5);
            plot(Vs_COR, Dz_loc, 'ob', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');


            if ~all(Vs_TONS == 0)
                plot(Vs_TONS, Dz_loc, '-r', 'LineWidth', 1.5);
                plot(Vs_TONS, Dz_loc, 'or', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            end
            legend("$V_{s, \rm CSF}$", "$V_{s, \rm cord}$", "$V_{s, \rm tons}$", 'interpreter', 'latex', 'Location','northwest', 'fontsize',14)

            yticks(-200:5:100);
        
            % Customize the appearance of the plot
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
            xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
            ylabel("$z \,{\rm [mm]}$", 'Interpreter', 'latex', 'FontSize', fs);
            % xlim([floor(min(Vs_SAS(:)) * 10) / 10, ceil(max(Vs_SAS(:)) * 10) / 10]);'\
            % xlim([0,0.7]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            set(gcf, 'Color', 'w');  % Set background color to white for figures
            grid off;
        end
        % title(tt, sprintf('$t/T = %.2f$', n / dat_PC.Nt{ii}), ...
        %         'Interpreter', 'latex', 'FontSize', fs);
        set(gcf, 'Color', 'w')
        movieVector(n) = getframe(gcf);
        drawnow;
    end

    % Set x-ticks for all flow rate tiles


end

function create_animation_ansys(dat_PC, loc, n)
    orange = [1, 0.5, 0];
    w_SAS  = -dat_PC.U_SAS{loc}(:,:,n);   % [cm/s]
    w_TONS = -dat_PC.U_TONS{loc}(:,:,n);  % [cm/s]
    w_COR = -dat_PC.U_COR{loc}(:,:,n);  % [cm/s]
    
    pcolor(w_SAS + w_TONS + w_COR);
    shading flat
    axis equal tight ij
    hold on
    box on
    colorbar;
    bluetored(dat_PC.venc{loc});
    xticklabels([]); yticklabels([]);
    
    % outlines
    contour(dat_PC.ROI_SAS{loc},  [0.5 0.5], 'k',      'LineWidth', 1.5);
    contour(dat_PC.ROI_TONS{loc}, [0.5 0.5], 'Color', orange, 'LineWidth', 1.5);
    contour(dat_PC.ROI_COR{loc}, [0.5 0.5], 'Color', 'b', 'LineWidth', 1.5);

    % filled COR region (semi-transparent red)
    % cor_mask  = dat_PC.ROI_COR{loc};
    % alphaFill = 0.35;
    % cor_color = [0.9 0.85 0.7];
    % B = bwboundaries(cor_mask,'noholes');
    % for k = 1:numel(B)
    %     b = B{k};  % [row, col]
    %     patch('XData', b(:,2), 'YData', b(:,1), ...
    %           'FaceColor', cor_color, 'FaceAlpha', alphaFill, ...
    %           'EdgeColor', 'k', 'HitTest','off','PickableParts','none');
    % end
    
    xlim([0.5 size(w_SAS,2)+0.5])
    ylim([0.5 size(w_SAS,1)+0.5])
    hold off
end