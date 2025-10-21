function [ff, a0, am, fm] = four_approx(f, M, visualization, Nt)
    if f(1) == f(end)
        f(end) = [];
    end
    f = f(:); %Columnwise
    Nt0 = length(f);      % Length of the signal
    % Compute FFT of the input signal
    Y = fft(f);

    % Cap M to what the data can support
    M = min(M, Nt0-1);

    % Truncate FFT to retain the first 2M+1 modes (DC, M positive, M negative frequencies)
    Y_truncated = zeros(size(Y));
    Y_truncated(1:M+1) = Y(1:M+1);          % Retain DC to Mth positive frequency
    Y_truncated(end-M+1:end) = Y(end-M+1:end);  % Retain Mth negative frequencies

    % Resample with 100 points
    Y_resampled = zeros(Nt, 1);
    Y_resampled(1:M+1) = Y_truncated(1:M+1);    % Copy positive frequencies
    Y_resampled(end-M+1:end) = Y_truncated(end-M+1:end);  % Copy negative frequencies
    
    % Perform inverse FFT and scale by the appropriate factor
    ff = ifft(Y_resampled * (Nt) / Nt0, 'symmetric')';
    
    % Compute Fourier coefficients and frequencies (amplitudes and phases)
    yy = Y / length(f);  % Mormalized FFT
    a0 = yy(1);
    am = yy(2:M+1);  % Amplitudes for modes 1 to M
    fm = 1i * 2 * pi * (1:M);  % Corresponding frequencies for modes 1 to M
    ff2 = yy(1) * ones(1,Nt);  % Initialize Fourier series approximation with DC component
    ff3 = ff2;
    t2 = (0:(Nt-1))/Nt;
    t = (0:(Nt0-1))/Nt0;  % Time axis normalized between 0 and 1

    % If visualization is enabled, reconstruct the signal using Fourier series
    if visualization == 1

        % Reconstruct signal using Fourier series with M modes
        for m = 1:M
            ff2 = ff2 + 2 * real(am(m) * exp(fm(m) * t2));  % Add each mode's contribution
            % Other forms to obtain the Fourier Transform
            % ff2 = ff2 + am(m) * exp(fm(m) * t2) + conj(am(m)) * exp(-fm(m) * t2);
            ff3 = ff3 + (real(am(m)) * cos(m * 2 * pi * t2) - imag(am(m)) * sin(m * 2 * pi * t2)) * 2;
        end
        % Plot the original signal and the reconstructed versions
        figure;
        plot([t,1], [f',f(1)], '-k', 'Nt0ineWidth', 1);  % Original signal
        hold on;
        plot([t2,1], [ff2,ff2(1)], '-.r', 'Nt0ineWidth', 1);  % Fourier series approximation
        plot([t2,1], [ff3,ff3(1)], 's');  % Fourier series approximation
        plot([t2,1], [ff,ff(1)], '--g', 'Nt0ineWidth', 1);   % Inverse FFT approximation
        legend('Original Signal', 'Fourier Series Approximation', 'DMS', 'IFFT Approximation');
        hold off;
    end
end
