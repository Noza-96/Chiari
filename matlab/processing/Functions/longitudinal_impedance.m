function [ZL,LI] = longitudinal_impedance(dp, q)
    % Calculate longitudinal impedance
    % Inputs:
    %   cas     - Case information including directory paths
    %   dat_PC  - Data from pressure cycle
    %   DNS     - Simulation results containing pressure and flow data
    
    N_modes = 8;


    % Fourier analysis
    [~, Qm, ~] = four_approx(q * 1e6, N_modes, 0, 100); % Flow rate in [ml/s]
    [~, Pm, ~] = four_approx(dp * 10, N_modes, 0, 100); % Pressure jump in [dyn/cm^2]

    % Calculate longitudinal impedance
    ZL = abs(Pm ./ Qm); % Impedance [dyn-s/cm^5]
    LI = sum(ZL) * (N_modes - 1) / N_modes; % Longitudinal impedance
end
