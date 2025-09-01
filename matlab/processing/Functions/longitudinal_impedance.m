function [ZL,LI] = longitudinal_impedance(dp, q)
    % Calculate longitudinal impedance
    % Inputs:
    %   cas     - Case information including directory paths
    %   dat_PC  - Data from pressure cycle
    %   DNS     - Simulation results containing pressure and flow data
    
    N_modes = 10;
    f = [1:N_modes]*1/1.14;
    % Restrict to 1–8 Hz
    f_min = 1; 
    f_max = 8;


    % Fourier analysis
    [~, ~, Qm, ~] = four_approx(q * 1e6, N_modes, 0, 100); % Flow rate in [ml/s]
    [~, ~, Pm, ~] = four_approx(dp * 10, N_modes, 0, 100); % Pressure jump in [dyn/cm^2]
    
    % Calculate longitudinal impedance
    ZL = abs(Pm ./ Qm)'; % Impedance [dyn-s/cm^5]

    % Interpolate ZL at the exact endpoints
    ZL_min = interp1(f, ZL, f_min, 'linear');
    ZL_max = interp1(f, ZL, f_max, 'linear');



    % Augment arrays with the clipped endpoints
    f_clip = [f_min, f(f>=f_min & f<=f_max), f_max];
    ZL_clip = [ZL_min, ZL(f>=f_min & f<=f_max), ZL_max];

    % figure
    % plot(f_clip, ZL_clip*1e6, '-o')
    
    % Piecewise-linear integral = trapezoidal rule
    LI = trapz(f_clip, ZL_clip);
end
