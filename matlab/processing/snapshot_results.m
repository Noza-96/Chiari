function snapshot_results(cas, subject, case_name, mesh_size, selected_times)

    Ncases = length(case_name); 
    DNS_cases = cell (1,Ncases);
    st_DNS = cell (1,Ncases);



    sstt = {"Peak rostral flow ", "Flow reversal ", "Peak caudal flow "};

    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
    Ndat = length(pcmri.locations); % number of slices

    if any(cellfun(@(s) ~isempty(regexp(s, '^cl|^cn', 'once')), case_name))
        fig_ind = 4;
        loc_plot = 2:Ndat-1;
        k_aux = 2;
    else
        fig_ind = 3;
        loc_plot = 1:Ndat;
        k_aux = 1;
    end

    load(fullfile(cas.dirmat,"DNS-results", "DNS_c0top_dx00002.mat"), 'DNS');
    DNS_roi=DNS;
    % DNS_roi_n=DNS;
    % index_n = ii;
    colo_lim = [6,3,6];
    
    for ii = 1:Ncases
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{ii});
        DNS_cases{ii} = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        load(fullfile(cas.dirmat,"DNS-results", "DNS_" + DNS_cases{ii} + ".mat"), 'DNS');
        st_DNS{ii} = DNS;
    end

    % Construct RMSE summary table [cm/s] with models as rows and locations as columns
rmse_table = cell(Ncases, Ndat); % (I–V) x (UPFM to C3–C4)
row_names = compose('(%s)', roman(1:Ncases));
col_names = pcmri.locations;

for kk = 1:Ncases
    RMSE_case = st_DNS{kk}.RMSE; % cell array (Ndat x 1), each cell is Nt x 1
    for loc = 1:Ndat
        if isempty(RMSE_case{loc})
            rmse_table{kk, loc} = '';
        else
            vals_selected = RMSE_case{loc}(selected_times); % correct indexing: select t/T = 0.4, 0.7, 0.8
            rmse_cm = vals_selected(:)' * 1e2;               % convert to cm/s
            rmse_table{kk, loc} = sprintf('[%.2f, %.2f, %.2f]', rmse_cm);
        end
    end
end

% Convert to table
T_rmse = cell2table(rmse_table, 'RowNames', row_names, 'VariableNames', col_names);

% Display and optionally export
disp('RMSE summary table [cm/s] for t/T = [0.4, 0.7, 0.8]:')
disp(T_rmse)
    x_roi = DNS_roi.slices.x;
    y_roi = DNS_roi.slices.y;

    roi = cell(1, Ndat);
    for kk = 1:Ndat    
        roi{kk} = DNS_roi.slices.u_normal{kk}(:,1)==0;
    end

    pcmri = apply_roi_pcmri(pcmri);

    for nt = 1:length(selected_times)
        n = selected_times(nt);
        fig = figure('Position', [100, 100, 100*(Ncases+2), 70*length(loc_plot)]);
        tt = tiledlayout(length(loc_plot), Ncases + 2, "TileSpacing", "tight", "Padding", "loose");

        for loc = loc_plot
            % PC-MRI data
            create_animation_ansys(pcmri, loc, Ndat, n, 1 + (Ncases+1+1)*(loc-k_aux), Ncases, roi{loc}, x_roi{loc}, y_roi{loc});
            bluetored(colo_lim(nt));
            colorbar off;
            for kk = 1:Ncases
                if isfield(st_DNS{kk}, 'RMSE_space') && isfield(st_DNS{kk}.RMSE_space, 'u_normal')
                % The field exists and is not empty
                    vel_data = st_DNS{kk}.RMSE_space;
                else
                    vel_data = st_DNS{kk}.slices;
                end
                create_animation_ansys(vel_data, loc, Ndat, n, 1 + 1 + kk + (Ncases+1+1)*(loc-k_aux), Ncases, roi{loc}, x_roi{loc}, y_roi{loc});
                bluetored(colo_lim(nt));
                colorbar off;
                % end
            end
        end

        print(gcf, fullfile(cas.dirfig, "snap_"+n+"_fig_"+fig_ind), '-depsc','-vector');

            figure('Position', [100, 100, 300, 70*length(loc_plot)]);
            x_L = 0;
    
            for kk = 1:Ncases
                RMSE_val = cellfun(@(x) x(n), st_DNS{kk}.RMSE)*1e2;
                plot(RMSE_val, 1:length(RMSE_val), '-o', 'MarkerSize',6,'LineWidth', 1.5)
                hold on
                x_L = max(x_L, max(RMSE_val));

            end
    
            ylim([loc_plot(1)-0.5,loc_plot(end)+0.5])
            xlim([0,ceil(x_L*10)/10])
            xticks(0:0.2:(ceil(x_L*10)/10-0.1))
            xticklabels([])
            yticks(loc_plot(1):1:loc_plot(end))
            yticklabels([]);
            ax = gca;
            ax.XGrid = 'off';
            ax.YGrid = 'on';
            set(gca, 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
            print(gcf, fullfile(cas.dirfig, "error_"+n+"_fig_"+fig_ind), '-depsc','-vector');


            legend({"I", "II", "III", "IV", "V"})      
            
    end
   
end

% create_animation_ansys(st_DNS{kk}.slices, loc, Ndat, n, 1 + kk + (Ncases+1)*(loc-2), Ncases, roi{loc}, x_roi{loc}, y_roi{loc});



%% auxiliary functions
function create_animation_ansys(data, loc, Ndat, n, ii, Ncases, roi_mask, x_raw, y_raw)
    
    fs = 12;
    % Extract data and rescale
    x = data.x{loc} * 1e2; % [cm]
    y = data.y{loc} * 1e2; % [cm]
    w = data.u_normal{loc}(:, n) * 1e2; % [cm/s]

    % Create interpolation grid
    xq = linspace(min(x), max(x), 1000);
    yq = linspace(min(y), max(y), 1000);
    [Xq, Yq] = meshgrid(xq, yq);
    Wq = griddata(x, y, w, Xq, Yq, 'cubic');

    % Plot in the specified tile
    nexttile(ii);
    scatter(x, y, 7, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    % bluetored(colo_lim(loc-1));

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
    box on;

    if ii ~= 1 + Ncases + (Ncases+1)*(loc-1) 
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
            k = boundary(x_roi_pts, y_roi_pts, 1);  % tight boundary
            plot(x_roi_pts, y_roi_pts, 'k', 'Marker', '.', 'LineStyle', 'none', 'MarkerSize', 2);
        catch
            % fallback if boundary fails
            plot(x_roi_pts, y_roi_pts, 'k.');
        end
    end

    hold off
end


end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
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
    q(n)
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

function r = roman(n)
    map = ["I", "II", "III", "IV", "V"];
    r = map(n);
end