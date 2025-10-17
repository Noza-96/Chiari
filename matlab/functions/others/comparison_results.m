function comparison_results(cas, case_name, mesh_size)

    Ncases = length(case_name); 
    DNS_cases = cell (1,Ncases);
    st_DNS = cell (1,Ncases);
    index_n = 0;

    load(fullfile(cas.dirmat, "DNS_c0top_dx00002.mat"), 'DNS');
    DNS_roi=DNS;
    
    for ii = 1:Ncases
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{ii});
        DNS_cases{ii} = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        load(fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_cases{ii} + ".mat"), 'DNS');
        st_DNS{ii} = DNS;
    end


    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
    Ndat = length(pcmri.locations); % number of slices
    
    x_roi =DNS_roi.slices.x;
    y_roi = DNS_roi.slices.y;
    % x_roi_n =DNS_roi_n.slices.x;
    % y_roi_n = DNS_roi_n.slices.y;
    roi = cell(1,Ndat);
    for kk = 1:Ndat    
        roi{kk} = DNS_roi.slices.u_normal{kk}(:,1)==0;
        % roi_n{kk} = DNS_roi_n.slices.u_normal{kk}(:,1)==0;
    end
    pcmri = apply_roi_pcmri(pcmri);
    
    fig = figure('Position', [100, 100, 150*(Ncases+1), 100*Ndat]);
    tiledlayout(Ndat, Ncases + 1, "TileSpacing", "tight", "Padding", "loose");
    
    % Preallocate movie vector
    numFrames = st_DNS{1}.ts_cycle;
    movieVector(numFrames) = struct('cdata', [], 'colormap', []);

    % Loop through time steps
    for n = 1:numFrames
        fprintf('Processing frame %d of %d\n', n, numFrames);
        for loc = 1:Ndat           
            % Plot PC-MRI data/results
            create_animation_ansys(pcmri, loc, Ndat, n, 1 + (Ncases+1)*(loc-1), Ncases, roi{loc}, x_roi{loc}, y_roi{loc});

            for kk = 1:Ncases
                if isfield(st_DNS{kk}, 'RMSE_space') && isfield(st_DNS{kk}.RMSE_space, 'u_normal')
                    vel_data = st_DNS{kk}.RMSE_space;
                else
                    vel_data = st_DNS{kk}.slices;
                end
                    create_animation_ansys(vel_data, loc, Ndat, n, 1 + kk + (Ncases+1)*(loc-1), Ncases, roi{loc}, x_roi{loc}, y_roi{loc});           
                % end
            end
        end

        % plot_flow_rate (pcmri.q{Ndat},n)
        
        % Capture the frame
        movieVector(n) = getframe(fig);
    end

    save_animation(movieVector, fullfile(cas.dirvid, "2D_comparison_" + strjoin(string([DNS_cases{:}]), '_vs_')));
end

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
    scatter(x, y, 10, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    bluetored(6);

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