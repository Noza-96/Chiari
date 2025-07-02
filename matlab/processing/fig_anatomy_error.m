
subject = "s101_b";
case_name ={"c3", "cl3_v2", "cl3_v3","cl3_v4"};
mesh_size = 0.0002;
    
    fs = 16;
    fan = 14;
    rows = 3;
    

    % Load MRI data
    mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");


    load(mri_data_path, 'cas');
    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');

    load(fullfile(cas.dirmat, "DNS_c0top_dx00002.mat"), 'DNS');
    DNS_roi=DNS;
    
    t = linspace(0, 1, pcmri.Nt);
    Ncases = length(case_name);
    colors = lines(Ncases);  % Unique colors per case

    st_DNS = cell(1, Ncases);
    
    for i = 1:Ncases
        case_i = case_name{i};
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_i);
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");

        if ~exist(data_path, 'file')
            fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
            continue
        end
        load(data_path, 'DNS');
        st_DNS{i} = DNS;
    end
    
    Ndat = pcmri.Ndat;
    % === Plotting ===
    %-----
    x_roi =DNS_roi.slices.x;
    y_roi = DNS_roi.slices.y;
    % x_roi_n =DNS_roi_n.slices.x;
    % y_roi_n = DNS_roi_n.slices.y;
    roi = cell(1,Ndat);
    for kk = 1:Ndat    
        roi{kk} = DNS_roi.slices.u_normal{kk}(:,1)==0;
        % roi_n{kk} = DNS_roi_n.slices.u_normal{kk}(:,1)==0;
    end
        
    fig = figure('Position', [100, 100, 100*(Ncases), 300]);
    tt=tiledlayout(Ndat-2, Ncases , "TileSpacing", "tight", "Padding", "compact");
    % title(tt, '$\overline{\mathrm{RMSE}} \, \left[{\rm cm/s}\right]$', 'FontSize', fs, 'interpreter', 'latex');  % Title for the whole tiled layout
    title(tt, '$\overline{\mathrm{RMSE}}$', 'FontSize', 18, 'interpreter', 'latex');  % Title for the whole tiled layout

    for loc = 2:Ndat-1           
        % Plot PC-MRI data/results
        for kk = 1:Ncases
            ii = kk + (Ncases)*(loc-2);
            nexttile(ii);
            if isempty(st_DNS{kk})
            box on
                 xlabel(''); ylabel(''); xticks([]); yticks([]);
            continue
            end
            spatial_error_plot(st_DNS{kk}.RMSE_space, st_DNS{kk}.case, loc, Ndat, ii, Ncases, roi{loc}, x_roi{loc}, y_roi{loc}); 
        end
    end
    % title(tt, "$t/T = " +num2str(selected_times(nt)/100)+ "$", 'Interpreter', 'latex', 'fontsize', 18);
    
    print(gcf, fullfile(pwd,'Figures', 'fig_4_anatomy'), '-depsc','-vector');

    %% auxiliary functions
function spatial_error_plot(data, name_loc, loc, Ndat, ii, Ncases, roi_mask, x_raw, y_raw)
    fs = 12;
    % Extract data and rescale
    x = data.x{loc} * 1e2; % [cm]
    y = data.y{loc} * 1e2; % [cm]
    w = data.val{loc} * 1e2; % [cm/s]

    % Plot in the specified tile
    scatter(x, y, 10, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    colormap('parula');       % or 'parula', etc.
    caxis([0 2]);  % set the color limits'
    colorbar 'off'
    % bluetored(6);

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
    box on;
    % if n==1 && ii == 1 + (Ncases+1)*(loc-1) 
    %     named_location (gca, data.locations{loc}, fs)
    % end
    if ii ~= Ncases 
            colorbar off;
    end

    if ii == 1 + (Ncases+1)*(loc-1)
        ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
    else
        ylabel('');
    end

    if loc == Ndat
        xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
    end
     xlabel('');
     ylabel('');
     xticks([])
     yticks([])
    set(gcf, 'Color', 'w')

    

if exist('roi_mask', 'var') && ~isempty(roi_mask)
    hold on

    % Extract ROI points
    x_roi_pts = x_raw(roi_mask) * 1e2;  % [cm]
    y_roi_pts = y_raw(roi_mask) * 1e2;

    % Use boundary to extract the outer contour of the ROI points
    if ~isempty(x_roi_pts)
        try
            plot(x_roi_pts, y_roi_pts, 'k', 'Marker', '.', 'LineStyle', 'none', 'MarkerSize', 2);
        catch
            % fallback if boundary fails
            plot(x_roi_pts, y_roi_pts, 'k.');
        end
    end

    hold off
end


end

function named_location (gca, sstt, fs)
        % Get the position of the current tile (in normalized figure coordinates)
    ax = gca;  % Get the current axis handle
    axPos = ax.Position;  % Position of the axis [left, bottom, width, height]

    % Compute normalized figure coordinates for the top-left corner of the tile
    % Axes position is in normalized figure coordinates [0, 1], so adjust for annotation
    xPos = axPos(1);  % X position of the tile
    yPos = axPos(2) + axPos(4) ;  % Slightly offset from the top (5% from the top edge of the tile)
    width = 0.2 * axPos(3);  % Width of the textbox (20% of the tile's width)
    height = 0.05 * axPos(4);   % Height of the textbox (5% of figure height)

    % Position it in the top-left corner of the tile using normalized figure coordinates
   dim = [xPos, yPos, width, height];
    
    % Create the textbox
    annotation('textbox', dim, 'String', sstt, 'FontSize', fs, 'Color', 'black', ...
               'EdgeColor', 'none', 'BackgroundColor', 'none', 'Interpreter', 'latex');
end



function plot_flow_rate(q,n)
    prev_ax = gca; % Save the current axis before switching
    
    % Switch to ax1 and plot - to be completed
    ax1 = axes('Position', [0.15 0.12 0.08 0.04]);
    flow_rate(q, 0)
    % ylim([-2,2])
    hold on 
    xline(n/100,LineWidth=1)
    set(gca,"FontSize",8)
    ylabel(''); xticks('');
    xlabel(''); yticks('');
    hold off
    % Return to the previous axis after plotting in ax1
    axes(prev_ax);  % Restore the previous axis
    drawnow;

end