function create_animation(subject,u_MRI, Q_MRI, A_MRI, u, Q, A, t, x, y, cas, loc)

    % Step 1: Define figure settings and annotation
    [Y, X, ~] = find(u_MRI(:,:,1));
    DX = (max(X) - min(X) + 10) / 2;
    X0 = (max(X) + min(X)) / 2;
    Y0 = (max(Y) + min(Y)) / 2;

    figure; clf;
    layout = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    fs = 14; % Font size
    set(gcf, 'Position', [200, 200, 800, 600]);

    % Annotations for SAS areas
    annotation('textbox', [0.08, 0.48, .1, .1], 'String', sprintf('Area SAS = %.2f mm', A_MRI), ...
               'FitBoxToText', 'on', 'EdgeColor', 'none', 'BackgroundColor', 'none', ...
               'FontSize', fs, 'Color', 'k', 'Interpreter', 'latex');
    annotation('textbox', [0.57, 0.48, .1, .1], 'String', sprintf('Area SAS = %.2f mm', A * 1e4), ...
               'FitBoxToText', 'on', 'EdgeColor', 'none', 'BackgroundColor', 'none', ...
               'FontSize', fs, 'Color', 'k', 'Interpreter', 'latex');

    % Step 2: Iterate over each time step to update frames
    for n = 1:length(t)
        title(layout, sprintf('$t = %.2f$ s', t(n)), 'Interpreter', 'latex', 'FontSize', 20);    

        % Plot 1: MRI data
        nexttile(1)
        imagesc(u_MRI(:, :, n));
        bluetored(6);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
        xlabel('X [pixels]', 'Interpreter', 'latex', 'FontSize', fs);
        ylabel('Y [pixels]', 'Interpreter', 'latex', 'FontSize', fs);
        xlim([X0 - DX, X0 + DX]);
        ylim([Y0 - DX, Y0 + DX]);
        title("PC-MRI " + cas.locations{loc}, 'Interpreter', 'latex', 'FontSize', 16);

        % Plot 2: Ansys simulation data (Interpolated points)
        nexttile(2)
        xx = x * 1e3; yy = y * 1e3;
        Dx = (max(xx) - min(xx) + 4) / 2;
        x0 = (max(xx) + min(xx)) / 2;
        y0 = (max(yy) + min(yy)) / 2;

        scatter(xx, yy, 100, u{n}, 'filled', 'd'); % Interpolated velocity points
        bluetored(6);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
        c = colorbar;
        c.Label.String = '[cm/s]';
        xlim([x0 - Dx, x0 + Dx]);
        ylim([y0 - Dx, y0 + Dx]);
        xlabel('$x \,[{\rm mm}]$', 'Interpreter', 'latex', 'FontSize', fs);
        ylabel('$y \,[{\rm mm}]$', 'Interpreter', 'latex', 'FontSize', fs);
        title('Inlet Ansys', 'Interpreter', 'latex', 'FontSize', 16);
        box on

        % Plot 3: MRI flow rate over time
        nexttile(3)
        flow_rate(Q_MRI, n);

        % Plot 4: Simulated flow rate over time
        nexttile(4)
        flow_rate(Q, n);

        % Capture the current frame for animation
        set(gcf, 'Color', 'w');  % Set background color to white for figures
        movieVector(n) = getframe(gcf);
    end

    % Step 3: Create and save the animation as a video
    videoName = 'MRI_to_Ansys';
    videoWriter = VideoWriter(fullfile("Videos/"+subject+"/pre/", videoName));
    videoWriter.FrameRate = 5;
    open(videoWriter);
    writeVideo(videoWriter, movieVector);
    close(videoWriter);
end
