function movieVector = create_animation_pc(dat_PC)
    close all;
    fs = 20;
    fan = 14;
    % z-position compared to C3C4
    Dz_loc = cell2mat(dat_PC.locz);

    time_frames = round(linspace(1, dat_PC.Nt{1}, 30));

    % Preallocate movie vector
    Ndata = dat_PC.Ndat;
    movieVector(length(time_frames)) = struct('cdata', [], 'colormap', []);

    monitors = get(0, 'MonitorPositions');
    monitor1 = monitors(1, :);

    rows = 8;
    % Set up figure properties
    figure;

    % Keep width/height ratio from the original
    aspectRatio = 1000 / (Ndata*240); 
    
    % New desired height = 4/5 of monitor height
    newHeight = 0.8 * monitor1(4);
    
    % Corresponding width to preserve aspect ratio
    newWidth = aspectRatio * newHeight;
    
    % Center horizontally, keep a small top margin
    left = monitor1(1) + (monitor1(3) - newWidth) / 2;
    bottom = monitor1(2) + (monitor1(4) - newHeight) / 2;  % vertically centered
    % or instead of center, you can anchor top/bottom as you like
    
    % Apply new position
    set(gcf, 'Position', [left, bottom, newWidth, newHeight]);

    tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");
    idx = 0;
    for n = time_frames
        idx = idx + 1;
    
        % Loop through each flow data set
        for k = 1:Ndata
            nexttile(1+(k-1)*rows, [1, 3]);
          
            contour_velocity(dat_PC, k, n);
            if k == 1
                title("$u\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
            
            t = [dat_PC.t{k},1];
            Q_SAS = [dat_PC.SAS.Q{k}, dat_PC.SAS.Q{k}(1)];
            Q_CORD = [dat_PC.CORD.Q{k}, dat_PC.CORD.Q{k}(1)];
            Q_TONS = [dat_PC.TONS.Q{k}, dat_PC.TONS.Q{k}(1)];
            offset_cond = dat_PC.SAS.fou.a0;              % 3×1 cell array
            offset_cond  = max(cellfun(@(x) abs(x), offset_cond));

            nexttile(4+(k-1)*rows, [1, 3]);
            plot(t, Q_SAS, Color='k', LineWidth=1.5)
            hold on 
            plot(t, Q_CORD, Color='b', LineWidth=1.5)
            if ~all(dat_PC.TONS.Q{k} == 0)
                plot(t, Q_TONS, Color='r', LineWidth=1.5)
            end
            
            if offset_cond > 0.1
                yline(simps(dat_PC.t{k}, dat_PC.SAS.Q{k}, 2), '--','Color', 'k', 'LineWidth', 1, 'HandleVisibility','off');            
                yline(simps(dat_PC.t{k}, dat_PC.CORD.Q{k}, 2), '--','Color', 'b', 'LineWidth', 1, 'HandleVisibility','off');           
                if ~all(dat_PC.TONS.Q{k} == 0)
                    yline(simps(dat_PC.t{k}, dat_PC.TONS.Q{k}, 2),'--', 'Color', 'r', 'LineWidth', 1, 'HandleVisibility','off')
                end
            end

            if k == 1
                legend("$Q_{\rm CSF}$", "$Q_{\rm cord}$", "$Q_{\rm tons}$", 'interpreter', 'latex','fontsize',14)
            end
            yline(0,':', 'LineWidth', 1,'HandleVisibility','off')
            xline (dat_PC.t{k}(n), '-', 'LineWidth', 1, 'HandleVisibility','off')
            hold off
            set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
            % Set x-tick labels conditionally
            if k < length(dat_PC.SAS.Q)
                xlabel([])
            else
                xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
            end
            xticks(0:0.5:1);

            if k == 1
                title("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            ymin = floor(min([dat_PC.SAS.Q{k}(:); dat_PC.TONS.Q{k}(:)]));
            ymax = ceil(max([dat_PC.SAS.Q{k}(:); dat_PC.TONS.Q{k}(:)]));
        
            % Set y-labels
            ylim([ymin, ymax]);
        end


        if idx == 1
            % Plot volumes in the last tile
            nexttile(7,[Ndata, 2]);
            plot(dat_PC.SAS.Vs, Dz_loc, '-k', 'LineWidth', 1.5);
            hold on
            plot(dat_PC.SAS.Vs, Dz_loc, 'ok', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            plot(dat_PC.CORD.Vs, Dz_loc, '-b', 'LineWidth', 1.5);
            plot(dat_PC.CORD.Vs, Dz_loc, 'ob', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');


            if ~all(dat_PC.TONS.Vs == 0)
                plot(dat_PC.TONS.Vs, Dz_loc, '-r', 'LineWidth', 1.5);
                plot(dat_PC.TONS.Vs, Dz_loc, 'or', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            end
            legend("$V_{s, \rm CSF}$", "$V_{s, \rm cord}$", "$V_{s, \rm tons}$", 'interpreter', 'latex', 'Location','northwest', 'fontsize',14)

            yticks(-10:0.5:10);
        
            % Customize the appearance of the plot
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
            xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
            ylabel("$z \,{\rm [mm]}$", 'Interpreter', 'latex', 'FontSize', fs);
            set(gcf, 'Color', 'w');  % Set background color to white for figures
            grid off;
        end
        set(gcf, 'Color', 'w')
        movieVector(idx) = getframe(gcf);
        drawnow;
    end
end



function contour_velocity(dat_PC, loc, n)
    orange = [1, 0.5, 0];
    w_SAS  = dat_PC.SAS.U{loc}(:,:,n);   % [cm/s]
    w_TONS = dat_PC.TONS.U{loc}(:,:,n);  % [cm/s]
    w_CORD = dat_PC.CORD.U{loc}(:,:,n);  % [cm/s]
    
    pcolor(w_SAS + w_TONS + w_CORD);
    shading flat
    axis equal tight ij
    hold on
    box on
    colorbar;
    bluetored(dat_PC.venc{loc});
    xticklabels([]); yticklabels([]);
    
    % outlines
    contour(dat_PC.SAS.ROI{loc},  [0.5 0.5], 'k',      'LineWidth', 1.5);
    % contour(dat_PC.CORD.ROI{loc}, [0.5 0.5], 'Color', 'b', 'LineWidth', 1.5);
    if sum(dat_PC.TONS.ROI{loc}(:)) > 0
        contour(dat_PC.TONS.ROI{loc}, [0.5 0.5], 'Color', orange, 'LineWidth', 1.5);
    end

    xlim([0.5 size(w_SAS,2)+0.5])
    ylim([0.5 size(w_SAS,1)+0.5])
    hold off
end