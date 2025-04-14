% Longitudinal evolution flow rate and stroke volume 

subjects = {"s101_b", "s101_a", "s101_aa"};

red   = [0.8500, 0.3250, 0.0980];  % warm red-orange
blue  = [0.0000, 0.4470, 0.7410];  % deep blue
green = [0.4660, 0.6740, 0.1880];  % vibrant green

color_m = {red, blue, green};

fs = 14;
fan = 8;
rows = length(subjects)*3+5;
Ndata = 5; 

% Set up figure properties
figure;
set(gcf, 'Position', [200, 200, 1000, Ndata*100]);
tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");

for s=1:length(subjects)
    subject = subjects{s};

    file_location = fullfile("../../../computations", "pc-mri", subject, "mat","03-apply_roi_compute_Q.mat"); 
    if exist(file_location)==0
        continue
    else
        load(file_location, 'cas','dat_PC');
        load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
        load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');
        locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
        % z-position compared to C3C4
        locz_vals = cell2mat(dat_PC.locz);
        Dz_loc = round(abs(locz_vals(end) - locz_vals)*10);
        % labels = cellfun(@(loc, dz) sprintf('%s (%d mm)', loc, dz), locations, num2cell(Dz_loc), 'UniformOutput', false)
        % Initialize variables
        Vs = zeros(1, length(dat_PC.Q_SAS));
    
    
    % Loop through each flow data set
    for k = 1:Ndata   
        Q = pcmri.q{k};
        t = linspace(0, 1, length(Q));  % Create time vector
        Vs(k) = 0.5 * simps(t, abs(Q), 2);  % Compute the volume
        nexttile(1+(s-1)*3+(k-1)*rows, [1, 3]);
        % Call the flow rate function
        flow_rate(Q, 0);
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
        % Set x-tick labels conditionally
        if k < length(dat_PC.Q_SAS)
            xlabel([])
        else
            xlabel("$t\, [{\rm s}]$", 'Interpreter', 'latex', 'FontSize', fs);
        end
        if s==1
            ylabel("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
        end

interval_t = 0.5;
xticks(0:interval_t:1);

x_ticks = 0:interval_t*dat_PC.T{k}:dat_PC.T{k};  % define tick positions
xticklabels(arrayfun(@(x) format_tick(x), x_ticks, 'UniformOutput', false));


            ylim([-2, 2]);
    end
    
    
    % Plot volumes in the last tile
    nexttile(rows-3,[Ndata, 3]);
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
    ylabel("$z \,{\rm [mm]}$", 'Interpreter', 'latex', 'FontSize', fs);
    xlim([floor(min(Vs(:)) * 10) / 10, ceil(max(Vs(:)) * 10) / 10]);
    ax = gca; % Get current axes
    % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
    set(gcf, 'Color', 'w');  % Set background color to white for figures
    grid off; 
    
    set(gcf, 'Color', 'w')
    end
end

print(gcf, fullfile(pwd,'Figures', 'fig_1'), '-depsc','-vector');

% Put this function at the end of your script
function label = format_tick(x)
    if x == 0
        label = sprintf('%d', x);      % No decimals for integers
    else
        label = sprintf('%.2f', x);    % Two decimals otherwise
    end
end

