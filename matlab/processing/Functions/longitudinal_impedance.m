%Calculate longitudinal impedance
function longitudinal_impedance(subject)
    % Define color schemes
    blue = [116, 124, 187] / 255;  
    red = [241, 126, 126] / 255;

    colorm = {blue,red};
   
    modes = 8;
    type = {'FLTG','FLTG-2'};

    % Initialize variables
    ZL = cell(1,length(type)); LI = cell(1,length(type));
    fs=14;
    figure
    for k = 1:length(type)
        load("data\"+subject+"\ansys_outputs\"+type{k}+"\flow_data.mat",'dp','Q');
        dp = dp(end-99:end);     Q = Q(end-99:end);
        [~, Qm, ~] = four_approx(Q*1e6, modes, 0); %Flow rate in [ml/s] - [cm3/s]
        [~, Pm, ~] = four_approx(dp*10, modes, 0); %Pressure jumo in  rate in [dyn/cm^2]
        ZL{k} = abs(Pm./Qm);
        LI{k} = sum(ZL{k})*(modes-1)/(modes);

        plot(ZL{k},'Color',colorm{k},'linewidth',1.5)
        hold on
    end
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);
    xlabel ("$f\left[{\rm Hz}\right]$",'Interpreter','latex',FontSize=fs)
    ylabel ("$Z_L\left[{\rm dyn-s}/{\rm cm}^5\right]$",'Interpreter','latex',FontSize=fs)
    legend(type,'interpreter','latex',FontSize=fs)
    xlim([1,8])
    ylim([0,100])

    saveas(gcf, fullfile("Figures", subject,"post","Longitudinal_impedance"), 'png');
    save("data/"+subject+"/Longitudinal_impedance.mat",'ZL','LI');
    disp('4. Longitudinal impedances calculated!')
end