% Create figure with segmentation together with MRI locations
function MRI_locations(subject, data_path, dat_PC, cas)
    % Open the existing figure
    fig1 = openfig(data_path + "/fig/pc-mri_locations.fig", 'invisible');
    ax1 = gca;  % Get the axes of the loaded figure

    Ndata = dat_PC.Ndat;

    % Set up figure properties
    row = 4;
    figure;
    set(gcf, 'Position', [200, 200, 1000, 600]);
    tt = tiledlayout(Ndata, row * 2, "TileSpacing", "tight", "Padding", "tight");

    % First tile - Copy axes from the existing figure
    if Ndata == 4
        nexttile(1,[4, 4]);
    elseif Ndata == 3 
        nexttile(1,[3, 4]);
    end
    axesObjs = findobj(ax1, 'Type', 'axes');  % Find all axes objects
    copyobj(get(axesObjs, 'Children'), gca);  % Copy all objects to the new tile
    view(90, 15);
    % zlim([-140, -40]);
    axis off;

    % Initialize variables
    Vs = zeros(1, length(dat_PC.Q_SAS));

    % Loop through each flow data set
    for k = 1:length(dat_PC.Q_SAS)
        Q = -dat_PC.Q_SAS{k};  % Get flow data
        Nt = dat_PC.Nt{k};     % Get number of time points
        t = linspace(0, 1, Nt);  % Create time vector

        % Create a new tile for the flow rate
        nexttile(5 + (k - 1) * row * 2, [1, 2]);
        Vs(k) = 0.5 * simps(t, abs(Q), 2);  % Compute the volume

        % Call the flow rate function
        flow_rate(Q, 0);

        % Set x-tick labels conditionally
        if k < length(dat_PC.Q_SAS)
            xticklabels([]);
            xlabel([])
        else
            xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', 20);
        end
        xticks(0:0.2:1);

        % Set y-labels
        ylabel("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', 20);
        ylim([-2, 2]);
        title(cas.locations{k}, 'Interpreter', 'latex', 'FontSize', 16);
    end

    % Set x-ticks for all flow rate tiles

    % Plot volumes in the last tile
    nexttile([Ndata, 1]);
    plot(Vs, Ndata:-1:1, 'o-', 'LineWidth', 1.5);
    yticks([]);

    % Customize the appearance of the plot
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 12);
    title("$V_s$", 'Interpreter', 'latex', 'FontSize', 16);
    xlim([floor(min(Vs(:)) / 0.05) * 0.05, ceil(max(Vs(:)) / 0.05) * 0.05]);
    set(gcf, 'Color', 'w');  % Set background color to white for figures
    saveas(gcf, fullfile("Figures", subject,"pre","MRI_locations"), 'png');
    disp('2. Visualized locations PC-MRI measurements and calculated flow rates...')
end
