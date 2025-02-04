function longitudinal_impedance(cas, DNS)
    % Calculate longitudinal impedance
    % Inputs:
    %   cas     - Case information including directory paths
    %   dat_PC  - Data from pressure cycle
    %   DNS     - Simulation results containing pressure and flow data

    % Define color schemes and font sizes
    red = [241, 126, 126] / 255;
    fs = 16;

    % Parameters
    N_modes = 8;
    dp = DNS.out.dp(end - DNS.ts_cycle + 1:end); % Pressure jump [Pa]
    q = DNS.out.q_bottom(end - DNS.ts_cycle + 1:end); % Flow rate [m^3/s]
    t = linspace(1 / DNS.ts_cycle, 1, 100); % Time vector for plotting

    % Plot flow rate and pressure jump
    figure;
    tiledlayout(1, 2);

    % Flow rate subplot
    nexttile;
    flow_rate(q * 1e6, 0); % Convert to [ml/s] and plot

    % Pressure jump subplot
    nexttile;
    flow_rate(dp, 0);
    ylabel("$\Delta p [{\rm Pa}]$", 'Interpreter', 'latex', 'FontSize', fs);
    ylim([min(dp(:)), max(dp(:))]);

    % Fourier analysis
    [~, Qm, ~] = four_approx(q * 1e6, N_modes, 0, 100); % Flow rate in [ml/s]
    [~, Pm, ~] = four_approx(dp * 10, N_modes, 0, 100); % Pressure jump in [dyn/cm^2]

    % Calculate longitudinal impedance
    DNS.ZL = abs(Pm ./ Qm); % Impedance [dyn-s/cm^5]
    DNS.LI = sum(DNS.ZL) * (N_modes - 1) / N_modes; % Longitudinal impedance

    % Plot impedance
    figure;
    plot(DNS.ZL, 'Color', red, 'LineWidth', 1.5);
    hold on;

    % Customize plot appearance
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);
    xlabel("$f\left[{\rm Hz}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
    ylabel("$Z_L\left[{\rm dyn-s}/{\rm cm}^5\right]$", 'Interpreter', 'latex', 'FontSize', fs);
    xlim([1, 8]);
    ylim([0, 100]);

    % Save results
    saveas(gcf, fullfile(cas.dirfig, "Longitudinal_impedance_"+DNS.case), 'png');
    save(fullfile(cas.dirmat, "DNS_" + DNS.case + ".mat"), 'DNS');

    % Display completion message
    disp('Longitudinal impedance calculated...');
end
