function Q0_ansys(subject,dat_PC,modes,animation)
    % Parameters
    An = -dat_PC.fou.am{end};
    t = linspace(0,1,100);  % Time vector
    Q = 0;          % Initialize flow variable
    T = dat_PC.T{end};
    
    % Initialize equation string
    file1 = '(';
    
    % Loop through modes
    for n = 1:modes
        real_part = real(An(n));
        imag_part = imag(An(n));
        
        % Build the Fourier series string
        file2 = "+" + num2str(real_part) + "*cos(" + num2str(n) + "*2*PI/"+num2str(T)+"*t*1[s^-1])";
        file3 = "-" + num2str(imag_part) + "*sin(" + num2str(n) + "*2*PI/"+num2str(T)+"*t*1[s^-1])";
        file1 = file1 + file2 + file3;
        
        % Update flow variables
        Q = Q + (real_part * cos(n * 2 * pi * t) - imag_part * sin(n * 2 * pi * t)) * 2;
    end
    
    % Finalize the equation string
    file1 = file1 + ")*2E-6[m^3/s]";
    fid = fopen("data/"+subject+"/ansys_inputs/FLTG-2/Q0.txt", 'wt');
    fprintf(fid, '%s\n', file1);
    fclose(fid);
    
    if animation == 1
    % Define colors 
        figure
        set(gcf, 'Position', [200, 200, 300, 200]);
        flow_rate(Q,0);
        set(gcf, 'Color', 'w');  % Set background color to white for figures
    end
    disp('3. Created text file Q0.txt with flow rate to introduce in ansys...')

end