% Create figure with segmentation together with MRI locations
function MRI_locations(dat_PC, cas, ts_cycle)
   
    fs = 12;
    fan = 8;
    locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
    load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');

    % Preallocate movie vector
    Ndata = dat_PC.Ndat;
    movieVector(ts_cycle) = struct('cdata', [], 'colormap', []);

    rows = 8;
    % Set up figure properties
    figure;
    set(gcf, 'Position', [200, 200, 600, 600]);
    tt = tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");

    % Initialize variables
    Vs = zeros(1, length(dat_PC.Q_SAS));

    for n = 1:ts_cycle
    
        % Loop through each flow data set
        for k = 1:Ndata
            nexttile(1+(k-1)*rows, [1, 3]);
            create_animation_ansys(pcmri, k, n, fan);
            ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
            if k == Ndata
                xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
            end

            Q = pcmri.q{k};  % Get flow data
            Nt = dat_PC.Nt{k};     % Get number of time points
            t = linspace(0, 1, ts_cycle);  % Create time vector
            if k == 1
                title("$u\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            % Create a new tile for the flow rate
            nexttile(4+(k-1)*rows, [1, 3]);
            Vs(k) = 0.5 * simps(t, abs(Q), 2);  % Compute the volume
    
            % Call the flow rate function
            flow_rate(Q, n);
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
    
            % Set y-labels
            ylim([-2, 2]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            % title(locations{k}, 'Interpreter', 'latex', 'FontSize', fs);

                    % Add title to the entire layout

        end

        if n == 1
            % Plot volumes in the last tile
            nexttile(7,[Ndata, 2]);
            plot(Vs, Ndata:-1:1, 'o-', 'LineWidth', 1.5);
            yticks(1:Ndata);
            yticklabels(flip(locations));
        
            % Customize the appearance of the plot
            set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
            title("$V_s {\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
            xlim([floor(min(Vs(:)) * 10) / 10, ceil(max(Vs(:)) * 10) / 10]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            set(gcf, 'Color', 'w');  % Set background color to white for figures
            grid on;
        end
        % title(tt, sprintf('$t/T = %.2f$', n / ts_cycle), ...
        %         'Interpreter', 'latex', 'FontSize', fs);
        set(gcf, 'Color', 'w')
        movieVector(n) = getframe(gcf);
        drawnow;
    end

    % Set x-ticks for all flow rate tiles

    save_animation(movieVector, fullfile(cas.dirvid, "flow_measurements"));

end

function create_animation_ansys(data, loc, n, fan)
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
    scatter(x, y, 8, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    bluetored(6);

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01], 'FontSize', fan);
    box on;
end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
end

