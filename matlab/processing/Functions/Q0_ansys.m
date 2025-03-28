function Q0_ansys(dat_PC, cas, modes, ts_cycle)
    % Create time vector and preallocate flow matrix
    t = linspace(0, 1, ts_cycle);  
    QQ = zeros(3, ts_cycle);  
    slice_indices = [1, dat_PC.Ndat];  
    file_names = ["Q_top.txt", "Q_bottom.txt"];

    % Process each slice (top and bottom)
    for k = 1:2
        % Extract Fourier coefficients and period
        An = -dat_PC.fou.am{slice_indices(k)};  
        T = dat_PC.T{slice_indices(k)};
        Q = zeros(1, ts_cycle);  
        equation_terms = strings(1, modes);  

        % Compute Fourier series representation
        for n = 1:modes
            omega_t = n * 2 * pi / T;
            real_part = real(An(n));
            imag_part = imag(An(n));

            % Construct equation term
            equation_terms(n) = sprintf("+%.6f*cos(%.6f*t*1[s^-1]) - %.6f*sin(%.6f*t*1[s^-1])", ...
                                        real_part, omega_t, imag_part, omega_t);

            % Compute flow rate
            Q = Q + 2 * (real_part * cos(omega_t * t) - imag_part * sin(omega_t * t));
        end

        % Assemble equation string
        equation_str = sprintf("(%s)*2E-6[m^3/s]", strjoin(equation_terms, ' '));

        equation_str = regexprep(equation_str, '\+-', '- ');
        equation_str = regexprep(equation_str, '-\s*-', '+ ');

        % Write equation to file
        file_path = fullfile(cas.diransys_in, file_names(k));
        writeToFile(file_path, equation_str);

        % Store flow rate
        QQ(k, :) = Q;
    end

    % Compute spinal cord flow rate
    QQ(3, :) = QQ(2, :) - QQ(1, :);

    % Plot flow rates
    plotFlowRates(QQ, cas, dat_PC);
    % Completion message
    disp('created .txt files with flow rates to introduce in ANSYS...');
end

function writeToFile(file_path, content)
    fid = fopen(file_path, 'wt');
    fprintf(fid, '%s', content);
    fclose(fid);
end

function plotFlowRates(QQ, cas, dat_PC)
    figure;
    tiledlayout(1, 3, "TileSpacing", "compact", "Padding", "compact");
    set(gcf, 'Position', [200, 200, 600, 200]);

    titles = [cas.locations{1}, cas.locations{dat_PC.Ndat}, "spinal cord"];
    
    for i = 1:3
        nexttile;
        flow_rate(QQ(i, :), 0);
        ylim([-2.5, 2.5]);
        title(titles{i});
    end

    % Set background color to white
    set(gcf, 'Color', 'w');
    saveas(gcf, fullfile(cas.dirfig, "flow_rate_cord"), 'png');
end
