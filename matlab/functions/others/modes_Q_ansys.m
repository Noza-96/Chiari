function modes_Q_ansys(subject,dat_PC,cas,modes,animation)
    % Parameters
    An = -dat_PC.fou.am{end};
    t = 0:0.001:1;  % Time vector
    Q = 0;          % Initialize flow variable
    QF = 0;         % Initialize flow with Fourier series
    
    % Initialize equation string
    file1 = '-(';
    
    % Loop through modes
    for n = 1:modes
        real_part = real(An(n));
        imag_part = imag(An(n));
        
        % Build the Fourier series string
        file2 = "+" + num2str(real_part) + "*cos(" + num2str(n) + "*2*PI*t*1[s^-1])";
        file3 = "-" + num2str(imag_part) + "*sin(" + num2str(n) + "*2*PI*t*1[s^-1])";
        file1 = file1 + file2 + file3;
        
        % Update flow variables
        Q = Q + (real_part * cos(n * 2 * pi * t) - imag_part * sin(n * 2 * pi * t)) * 2;
        QF = QF + An(n) * exp(1i * n * 2 * pi * t) + conj(An(n)) * exp(-1i * n * 2 * pi * t);
    end
    
    % Finalize the equation string
    file1 = file1 + ")*2E-6[m^3/s]";
    fid = fopen("data/"+subject+"/Q0_"+cas.locations{end}+".txt", 'wt');
    fprintf(fid, '%s\n', file1);
    fclose(fid);
    
    if animation == 1
        % Define colors
        blue = [116, 124, 187]/255;
        CSF = [138, 173, 193]/255;
        red = [241, 126, 126]/255;

        % Plot the flow profile
        figure
        set(gcf, 'Position', [200, 200, 300, 200]);
        plot(t, Q, '-', 'LineWidth', 1.5, 'Color', 'k');
        hold on;
        
        % Highlight the negative flow regions
        Q_neg = Q .* (Q < 0);
        area(t, Q, 'FaceColor', red);
        area(t, Q_neg, 'FaceColor', blue);
        
        % Add baseline
        plot(t, t * 0, '-', 'LineWidth', 1, 'Color', 'k');
        
        % Format plot
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01]);
        set(gca, 'FontSize', 12);
        xlabel("$t/T$", 'Interpreter', "latex", 'FontSize', 20);
        ylabel("$Q_{\rm "+cas.locations{end}+"}\left[{\rm ml/s}\right]$", 'Interpreter', "latex", 'FontSize', 20);
    end

end