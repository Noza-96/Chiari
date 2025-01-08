function Q0_ansys(dat_PC,cas,modes, ts_cycle)

    t = linspace(0,1,ts_cycle);  % Time vector
    QQ = zeros(3,ts_cycle);
    slice = [1, dat_PC.Ndat];
    for k = 1:2

        % Parameters
        An = -dat_PC.fou.am{slice(k)};
        Q = 0;          % Initialize flow variable
        T = dat_PC.T{slice(k)};
        
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
        if k == 1
            fid = fopen(fullfile(cas.diransys_in,"Q_top.txt"), 'wt');
        elseif k == 2
            fid = fopen(fullfile(cas.diransys_in,"Q_bottom.txt"), 'wt');
        end
        fprintf(fid, '%s\n', file1);
        fclose(fid);
        QQ(k,:) = Q; 
    end
        QQ(3,:) = - ( - QQ(1,:) + QQ(2,:));
        figure
        tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
        set(gcf, 'Position', [200, 200, 600, 200]);
        sstt = [cas.locations{1}, cas.locations{dat_PC.Ndat}, "spinal cord"]
        for i = 1:3
            nexttile
            flow_rate(QQ(i,:),0);
            ylim([-2.5, 2.5]);
            title(sstt{i})
        end
        set(gcf, 'Color', 'w');  % Set background color to white for figures
        disp('3. Created text files with flow rates to introduce in ansys...')
    
end