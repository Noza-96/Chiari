% Longitudinal evolution flow rate and stroke volume 

subjects = {"s101_b", "s101_a", "s101_ab"};

red   = [0.8500, 0.3250, 0.0980];  % warm red-orange
blue  = [0.0000, 0.4470, 0.7410];  % deep blue
green = [0.4660, 0.6740, 0.1880];  % vibrant green

color_m = {red, blue, green};

fs = 16;
fan = 10;
rows = 5;
Ndata = 5; 

% Set up figure properties
figure;
set(gcf, 'Position', [200, 200, 1000, Ndata*100]);
tiledlayout(Ndata, rows, "TileSpacing", "loose", "Padding", "tight");

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
        Dz_loc = round(abs(locz_vals(end) - locz_vals)*10);

    
    
    % Loop through each flow data set
    for k = 1:Ndata   
        Q = pcmri.q{k};
        t = linspace(0, 1, length(Q));  % Create time vector
        nexttile(1+(k-1)*rows, [1, 2]);
        plot(t*pcmri.T{k}, Q, 'Color', color_m{s}, 'LineStyle','-', LineWidth=1.5)
        hold on
        % Call the flow rate function
        % flow_rate(Q, 0);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);

        ylabel("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
        yline(0,LineWidth=1,LineStyle=":")

        % Set x-tick labels conditionally
        if k < pcmri.Ndat
            xlabel([])
        else
            xlabel("$t\, [{\rm s}]$", 'Interpreter', 'latex', 'FontSize', fs);
        end

        ylim([-2, 2]);

        max_vel = max(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}>0) + ...
                  min(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}<0);

        [max_vel, index] = max(abs(pcmri.u_normal{k}), [], 1);  % Find max of absolute values
        max_vel = 100*max_vel .* sign(pcmri.u_normal{k}(index + (0:size(pcmri.u_normal{k}, 2)-1) * size(pcmri.u_normal{k}, 1)));  % Preserve sign
        


        t = linspace(0, 1, pcmri.Nt);  % Create time vector
        nexttile(3+(k-1)*rows, [1, 2]);
        plot(t*pcmri.T{k}, max_vel, 'Color', color_m{s}, 'LineStyle','-', LineWidth=1.5)
        hold on
        % Call the flow rate function
        % flow_rate(Q, 0);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
        yline(0,LineWidth=1,LineStyle=":")

        ylabel("$u_{\rm max}\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);

        % Set x-tick labels conditionally
        if k < pcmri.Ndat
            xlabel([])
        else
            xlabel("$t\, [{\rm s}]$", 'Interpreter', 'latex', 'FontSize', fs);
        end
        
        Y_l = ceil(max(abs(max_vel(:))))+1;

        ylim([-Y_l, Y_l]);

        yticks([-Y_l,0,Y_l])

    end
    
    Vs = [pcmri.SV{:}]; 
    
    % Plot volumes in the last tile
    nexttile(rows,[Ndata, 1]);
    plot(Vs, Dz_loc, '-', 'LineWidth', 1.5, 'Color', color_m{s});
    hold on
    plot(Vs, Dz_loc, 'o', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'Color', color_m{s});
    
    yticks(-20:5:100);

    for i = 1:length(anatomy.Dz) - 2
    yline(anatomy.Dz(i), '--', anatomy.location{i}, ...
        'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontSize', fs);
    end             
    
    ylim([0, ceil(max(Dz_loc(:))/10)*10])
    
    % Customize the appearance of the plot
    set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
    ylabel("z {\rm [mm]}", 'Interpreter', 'latex', 'FontSize', fs);
    xlim([floor(min(Vs(:)) * 10) / 10, ceil(max(Vs(:)) * 10) / 10]);
    ax = gca; % Get current axes
    % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
    set(gcf, 'Color', 'w');  % Set background color to white for figures
    grid off; 
    
    set(gcf, 'Color', 'w')
    end
end

print(gcf, fullfile(pwd,'Figures', 'fig_1'), '-depsc','-vector');


