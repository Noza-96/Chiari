% Longitudinal evolution flow rate and stroke volume 
clear; close all
addpath('Functions/');
addpath('Functions/Others/')

subjects = {"s101_b"};

location_names = ["UPFM", "FM-C1", "C1-C2", "C2-C3", "C3-C4"];
subject_ids = {"pre-op", "3-mo post", "10-mo post"};

gray_c = [1,1,1]*0.3;

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

color_m = {red, blue, green};

fs = 16;
fan = 14;
rows = 3;
Ndata = 5; 

% Preallocate output table
data_table = table();


data_table.T       = NaN(length(subjects), Ndata);  % period
data_table.tT_s    = NaN(length(subjects), Ndata);  % onset systole calculated as time closer to t/T=0.5, with t/T>0.5 and Q<0
data_table.tT_d    = NaN(length(subjects), Ndata);  % onset diastole calculated as time closer to t/T=0.5, with t/T<0.5 and Q<0
data_table.max_vel_pos = NaN(length(subjects), Ndata);
data_table.max_vel_neg = NaN(length(subjects), Ndata);
data_table.Qmax_s  = NaN(length(subjects), Ndata);  % maximum negative flow rate
data_table.Qmax_c  = NaN(length(subjects), Ndata);  % maximum positive flow rate
data_table.Vs      = NaN(length(subjects), Ndata);  % stroke volume
data_table.Dz      = NaN(length(subjects), Ndata);  % stroke volume


t_T= [0.4, 0.7, 0.8];

% Set up figure properties
figure;
set(gcf, 'Position', [200, 200, 450, Ndata*100]);
tiledlayout(Ndata, rows, "TileSpacing", "loose", "Padding", "tight");

Y_l = zeros(1,Ndata);

for s=1:length(subjects)
    subject = subjects{s};

    file_location = fullfile("../../../computations", "pc-mri", subject, "mat","04-registration.mat"); 
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
        
        % Cardiac period
        T = pcmri.T{k};

          % Find (t/T)_s: first time > 0.5 where Q < 0
        idx_s = find(t > 0.5 & Q < 0, 1, 'first');
        tT_s = t(idx_s);
    
        % Find (t/T)_d: last time < 0.5 where Q < 0
        idx_d = find(t < 0.5 & Q < 0, 1, 'last');
        tT_d = t(idx_d);
    
        % Peak flows
        Q_s = min(Q);  % systolic (caudal)
        Q_d = max(Q);  % diastolic (rostral)
    

        data_table.T(s, loc)        = T;
        data_table.tT_s(s, loc)     = tT_s;
        data_table.tT_d(s, loc)     = tT_d;
        data_table.Qmax_s(s, loc)   = Q_s;
        data_table.Qmax_c(s, loc)   = Q_d;
        data_table.Vs(s, loc)       = pcmri.SV{k};
        data_table.Dz(s, loc)       = Dz_loc(k);

    
               
        % dimensional with *pcmri.T{k}
        nexttile(1+(loc-1)*rows, [1, 2]);
        % plot(t, Q, 'Color', color_m{s}, 'LineStyle','-', LineWidth=1.5)
        hold on
        % Call the flow rate function
        flow_rate(Q, 0);
        box on
        hold on
        set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    
        for j = 1:length(t_T)
             plot([t_T(j), t_T(j)], [-3,3], 'LineStyle', '--', 'Color', gray_c, 'LineWidth', 0.5);
             % plot(t_T(j), Q(t_T(j)*100), 'o', 'Color', gray_c, 'LineWidth', 0.5);
        end
        ylabel("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
        yline(0,LineWidth=1,LineStyle=":")

        % Set x-tick labels conditionally
        if k < pcmri.Ndat
            xlabel([])
            xticklabels([])
        else
            xlabel("Cardiac cycle $(t/T)$", 'Interpreter', 'latex', 'FontSize', fs);
        end

        ylim([-2.5, 2.5]);

        max_vel = max(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}>0) + ...
                  min(pcmri.u_normal{k}, [], 1).*(pcmri.q{k}<0);

        [max_vel, index] = max(abs(pcmri.u_normal{k}), [], 1);  % Find max of absolute values
        max_vel = 100*max_vel .* sign(pcmri.u_normal{k}(index + (0:size(pcmri.u_normal{k}, 2)-1) * size(pcmri.u_normal{k}, 1)));  % Preserve sign
        xticks(0:0.2:1);    

        % Find max positive and negative velocities (cm/s)
        u = pcmri.u_normal{k};  % [space x time]
        max_u_pos = max(u, [], 1);  % max at each time
        max_u_neg = min(u, [], 1);
        
        % Take maximum across time (positive and negative separately)
        max_vel_pos = 100 * max(max_u_pos);  % cm/s
        max_vel_neg = 100 * min(max_u_neg);  % cm/s
        
        data_table.max_vel_pos(s, loc) = max_vel_pos;
        data_table.max_vel_neg(s, loc) = max_vel_neg;


    end
    
    Vs{s} = [pcmri.SV{:}]; 
    Dz{s} = Dz_loc;
 

    end
end

nexttile(rows,[Ndata, 1]);

for s=1:length(subjects)
    plot(Vs{s}, Dz{s}/10, '-', 'LineWidth', 1.5, 'Color', color_m{s});
    hold on    
    yticks(-5:1:0.5);          
    
    ylim([-6, 1])
    
    % Customize the appearance of the plot
    set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
    ylabel("z {\rm [cm]}", 'Interpreter', 'latex', 'FontSize', fs);
    ax = gca; % Get current axes
    % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
    set(gcf, 'Color', 'w');  % Set background color to white for figures
    grid off; 
    xlim([0, 0.8]);
    xticks(0:0.4:1); 
    % xticklabels(0:0.4:0.8);

    set(gcf, 'Color', 'w')
end

yline(0,LineWidth=1,LineStyle=":")
% for i = 1:length(anatomy.Dz) - 2
%              plot([0, 1], [-anatomy.Dz(i)/10,-anatomy.Dz(i)/10], 'LineStyle', '-', 'Color', gray_c, 'LineWidth', 0.5);
% end   

marker = {'o','o','o'};
for s=1:length(subjects)
    plot(Vs{s}, Dz{s}/10, marker{s}, 'MarkerSize',7,'LineWidth', 1, 'MarkerFaceColor', [1,1,1]*0.5, 'Color', color_m{s}, 'MarkerEdgeColor',color_m{s});
end


print(gcf, fullfile(pwd,'Figures', 'fig_1'), '-depsc','-vector');


% Initialize new table with 15 rows
output_table = table();

        Ndig = 2;

row_idx = 1;
for loc = 1:Ndata
    for s = 1:length(subjects)
        % Skip if the entry was never filled (NaN in T indicates missing data)
        if isnan(data_table.T(s, loc))
            continue
        end



        output_table.Loc{row_idx,1}   = char(location_names(loc));
        output_table.Subj{row_idx,1}  = char(subject_ids{s});
        output_table.Dz(row_idx,1)         = round(data_table.Dz(s, loc), Ndig);
        output_table.T(row_idx,1)          = round(data_table.T(s, loc), Ndig);
        output_table.tT_s(row_idx,1)       = round(data_table.tT_s(s, loc), Ndig);
        output_table.DT_s(row_idx,1)       = round(1 - (data_table.tT_s(s, loc) - data_table.tT_d(s, loc)), Ndig);
        output_table.Qmax_c(row_idx,1)     = round(data_table.Qmax_c(s, loc), Ndig);
        output_table.Qmax_s(row_idx,1)     = round(data_table.Qmax_s(s, loc), Ndig);
        output_table.max_vel_pos(row_idx,1) = round(data_table.max_vel_pos(s, loc), Ndig);
        output_table.max_vel_neg(row_idx,1) = round(data_table.max_vel_neg(s, loc), Ndig);
        output_table.Vs(row_idx,1)         = round(data_table.Vs(s, loc), Ndig);



        row_idx = row_idx + 1;
    end
end

output_table.Properties.VariableNames = { ...
    'Loc', 'Subj', 'z (mm)', 'T (s)', '(t/T)_s', 'D(t/T)_s', 'Q_max (+) [ml/s]', 'Q_max (-) [ml/s]', 'u_max (+) [cm/s]', 'u_max (-) [cm/s]', 'Vs (ml)' ...
};

% Display the result
disp(output_table)

