% Longitudinal evolution flow rate and stroke volume 
clear; close all
subjects = {"s101_b", "s101_a", "s101_aa"};

red   = [0.8500, 0.3250, 0.0980];  % warm red-orange
blue  = [0.0000, 0.4470, 0.7410];  % deep blue
green = [0.4660, 0.6740, 0.1880];  % vibrant green

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

color_m = {red, blue, green};

fs = 16;
fan = 10;
rows = 5;
Ndata = 5; 

% Set up figure properties
figure;
set(gcf, 'Position', [200, 200, 1000, Ndata*100]);
tiledlayout(Ndata, rows, "TileSpacing", "loose", "Padding", "tight");

Y_l = zeros(1,Ndata);

for s=1:length(subjects)
    subject = subjects{s};

    file_location = fullfile("../../../computations", "pc-mri", subject, "mat","03-apply_roi_compute_Q.mat"); 
    if exist(file_location)==0
        continue
    else
        load(file_location, 'cas');
        load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
        load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');
        locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
        % z-position compared to C3C4
        locz_vals = cell2mat(pcmri.locz);
        Dz_loc = -(anatomy.FM-(-locz_vals*10));

    
    
    % Loop through each flow data set
    for loc = 1:Ndata   
        if subject == "s101_a" || subject == "s101_aa"
            k = loc-1;
            if loc == 1
                continue
            end
        else 
            k = loc;
        end
        Q = pcmri.q{k};
        t = linspace(0, 1, length(Q));  % Create time vector
        % dimensional with *pcmri.T{k}
        nexttile(1+(loc-1)*rows, [1, 2]);
        plot(t, Q, 'Color', color_m{s}, 'LineStyle','-', LineWidth=1.5)
        hold on
        % Call the flow rate function
        % flow_rate(Q, 0);
        set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);

        ylabel("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
        yline(0,LineWidth=1,LineStyle=":")

        % Set x-tick labels conditionally
        if k < pcmri.Ndat
            xlabel([])
        else
            xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
        end

        ylim([-2.5, 2.5]);

        max_vel = max(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}>0) + ...
                  min(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}<0);

        [max_vel, index] = max(abs(pcmri.u_normal{k}), [], 1);  % Find max of absolute values
        max_vel = 100*max_vel .* sign(pcmri.u_normal{k}(index + (0:size(pcmri.u_normal{k}, 2)-1) * size(pcmri.u_normal{k}, 1)));  % Preserve sign
        


        t = linspace(0, 1, pcmri.Nt);  % Create time vector
        nexttile(3+(loc-1)*rows, [1, 2]);
        plot(t, max_vel, 'Color', color_m{s}, 'LineStyle','-', LineWidth=1.5)
        hold on
        % Call the flow rate function
        % flow_rate(Q, 0);
        set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
        yline(0,LineWidth=1,LineStyle=":")

        ylabel("$u_{\rm max}\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);

        % Set x-tick labels conditionally
        if k < pcmri.Ndat
            xlabel([])
        else
            xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
        end
        
        Y_l(k) = max(ceil(max(abs(max_vel(:))))+1,Y_l(k));

        ylim([-Y_l(k), Y_l(k)]);

        yticks([-Y_l(k),0,Y_l(k)])

    end
    
    Vs{s} = [pcmri.SV{:}]; 
    Dz{s} = Dz_loc;
 

    end
end

nexttile(rows,[Ndata, 1]);

for s=1:length(subjects)
    plot(Vs{s}, Dz{s}, '-', 'LineWidth', 1.5, 'Color', color_m{s});
    hold on    
    yticks(-100:5:100);          
    
    ylim([-60, 10])
    
    % Customize the appearance of the plot
    set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
    ylabel("z {\rm [mm]}", 'Interpreter', 'latex', 'FontSize', fs);
    ax = gca; % Get current axes
    % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
    set(gcf, 'Color', 'w');  % Set background color to white for figures
    grid off; 
    xlim([0, 0.8]);

    set(gcf, 'Color', 'w')
end
for i = 1:length(anatomy.Dz) - 2
yline(-anatomy.Dz(i), '--', anatomy.location{i}, ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontSize', fs-2);
end   

marker = {'o','o','o'};
for s=1:length(subjects)
    plot(Vs{s}, Dz{s}, marker{s}, 'MarkerSize',7,'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'Color', color_m{s}, 'MarkerEdgeColor',color_m{s});
end




print(gcf, fullfile(pwd,'Figures', 'fig_1'), '-depsc','-vector');


