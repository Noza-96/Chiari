function [ff, am, fm] = four_approx(f, N, visualization)
    if f(1) == f(end)
        f(end) = [];
    end
    L = length(f);      % Length of the signal
    % Compute FFT of the input signal
    Y = fft(f);

    % Truncate FFT to retain the first 2N+1 modes (DC, N positive, N negative frequencies)
    Y_truncated = zeros(size(Y));
    Y_truncated(1:N+1) = Y(1:N+1);          % Retain DC to Nth positive frequency
    Y_truncated(end-N+1:end) = Y(end-N+1:end);  % Retain Nth negative frequencies

    % Resample with 100 points
    Npoints = 100;
    Y_resampled = zeros(Npoints, 1);
    Y_resampled(1:N+1) = Y_truncated(1:N+1);    % Copy positive frequencies
    Y_resampled(end-N+1:end) = Y_truncated(end-N+1:end);  % Copy negative frequencies
    
    % Perform inverse FFT and scale by the appropriate factor
    ff = ifft(Y_resampled * (Npoints) / L, 'symmetric')';
    
    % Compute Fourier coefficients and frequencies (amplitudes and phases)
    yy = fft(f) / length(f);  % Normalized FFT
    am = yy(2:N+1);  % Amplitudes for modes 1 to N
    fm = 1i * 2 * pi * (1:N);  % Corresponding frequencies for modes 1 to N
    ff2 = yy(1) * ones(1,Npoints);  % Initialize Fourier series approximation with DC component
    t2 = (0:(Npoints-1))/Npoints;
    t = (0:(L-1))/L;  % Time axis normalized between 0 and 1

    % If visualization is enabled, reconstruct the signal using Fourier series
    if visualization == 1

        % Reconstruct signal using Fourier series with N modes
        for m = 1:N
            ff2 = ff2 + 2 * real(am(m) * exp(fm(m) * t2));  % Add each mode's contribution
            % Other forms to obtain the Fourier Transform
            % ff2 = ff2 + am(m) * exp(fm(m) * t2) + conj(am(m)) * exp(-fm(m) * t2);
            % ff2 = ff2 + (real(am(m)) * cos(m * 2 * pi * t2) - imag(am(m)) * sin(m * 2 * pi * t)) * 2;
        end

        % Plot the original signal and the reconstructed versions
        figure;
        plot([t,1], [f,f(1)], '-k', 'LineWidth', 1);  % Original signal
        hold on;
        plot([t2,1], [ff2,ff2(1)], '-.r', 'LineWidth', 1);  % Fourier series approximation
        plot([t2,1], [ff,ff(1)], '--g', 'LineWidth', 1);   % Inverse FFT approximation
        legend('Original Signal', 'Fourier Series Approximation', 'IFFT Approximation');
        hold off;
    end
end
