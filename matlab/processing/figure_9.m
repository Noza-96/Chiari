clear; close all
subject = "s101_b";
mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
load(mri_data_path, 'cas', 'dat_PC');
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
pcmri = apply_roi_pcmri(pcmri);

mesh_size = 0.0002;

fs = 16;
fan = 14;
ft = 12;

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

nt = 80;
sli = 3;

% Localize anterior and posterior pixels
[t_geom, t_sim, b_inlet, version] = get_type_simulation("cl3_v1");
DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
load(data_path, 'DNS');
n_slices = length(DNS.RMSE_space.x)-1;
anterior_idx = cell(size(DNS.RMSE_space.x));

% figure
% tiledlayout(1,n_slices-1, "TileSpacing", "loose", "Padding", "tight");
% set(gcf, 'Position',[100,100,1000,400])
for k = 2:n_slices
    % nexttile
    anterior_idx{k} = plot_pressure(DNS.RMSE_space, k, k, 30);
    % Anterior == 1; Posterior == 0
    % pause
end

% Calculate and plot flow rate in anterior-posterior region

case_name = ["c3", "cl3_v1"];

dx = dat_PC.dx/1000; % [m]
dy = dat_PC.dy/1000; % [m]
dA = dx*dy;

line_s = [':', '-'];

figure
tiledlayout(n_slices-1, 2, "TileSpacing", "compact", "Padding", "compact")
set(gcf, 'Position',[100,100,400,400])

color_m = {blue, red};
tt = (0:(100-1))/(100);

Error_ant_i = zeros(1,n_slices-1);
Error_post_i = zeros(1,n_slices-1);

Error_ant = cell(1,length(case_name));
Error_post = cell(1,length(case_name));

for n_case = 1:length(case_name)
    
    
    for k = 2:n_slices
        u = pcmri.u_normal{k};
        Nt = size(u,2);
        Q_ant_pc = zeros(Nt, 1);
        Q_post_pc = zeros(Nt, 1);
        nexttile (k-1)
        for nt = 1:size(u,2)
            Q_ant_pc(nt) = sum(u(:,nt).*anterior_idx{k}*dA);
            Q_post_pc(nt) = sum(u(:,nt).*(~anterior_idx{k})*dA);
        end
        if n_case == 1
            nexttile (2*(k-1)-1)
            flow_rate_trans(Q_ant_pc*1e6)
            % plot(0:0.01:1,[Q_ant_pc;Q_ant_pc(1)]*1e6, 'Color','k', 'LineStyle','-', LineWidth=1.5)
            hold on 
            if k < n_slices
                xticklabels([])
                xlabel([])
            end
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
            ylabel('$Q(t)$', 'Interpreter', 'latex', 'FontSize', fs);
    
            Vs = simps(tt*1.14,0.5*abs(Q_ant_pc*1e6));
            A = sum(anterior_idx{k})*dA * 1e4; %cm^2
    
            % Add annotation (place in upper-left corner of current axes)
            xPos = 0.05; % relative to x-axis
            yPos = -1.1;  % relative to y    -axis
            Dy = 0.35;
            if k == 2
                text(xPos, yPos, "$V_s = " + round(Vs,2) +" \,{\rm ml}$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
                text(xPos, yPos+Dy, "$A = " + round(A,2) +" \,{\rm cm}^2$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
            else
                text(xPos, yPos, "$ " + round(Vs,2) +" \,{\rm ml}$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
                text(xPos, yPos+Dy, "$" + round(A,2) +" \,{\rm cm}^2$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
            end
    
            nexttile (2*(k-1))
            % plot(0:0.01:1,[Q_post_pc;Q_post_pc(1)]*1e6, 'Color','k', 'LineStyle','-', LineWidth=1.5)
            flow_rate_trans(Q_post_pc*1e6)
            hold on
            if k < n_slices
                xticklabels([])
                xlabel([])
            end
            yticklabels([])
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    
            Vs = simps(((0:(100-1))/(100))*1.14,0.5*abs(Q_post_pc*1e6));
            A = sum(~anterior_idx{k})*dA * 1e4; %cm^2
    
            % Add annotation (place in upper-left corner of current axes)
            if k == 2
                text(xPos, yPos, "$V_s = " + round(Vs,2) +" \,{\rm ml}$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
                text(xPos, yPos+Dy, "$A = " + round(A,2) +" \,{\rm cm}^2$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');  
            else
                text(xPos, yPos, "$ " + round(Vs,2) +" \,{\rm ml}$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
                text(xPos, yPos+Dy, "$" + round(A,2) +" \,{\rm cm}^2$", 'Interpreter', 'latex','Color', [1,1,1]*0.3 ,'FontSize', ft, 'FontWeight', 'bold','BackgroundColor', 'none', 'HorizontalAlignment', 'left');
            end        
        end

        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{n_case});
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        load(data_path, 'DNS');
        
        u = DNS.RMSE_space.u_normal{k};
        Nt = size(u,2);
        Q_ant = zeros(Nt, 1);
        Q_post = zeros(Nt, 1);
        for nt = 1:size(u,2)
            Q_ant(nt) = sum(u(:,nt).*anterior_idx{k}*dA);
            Q_post(nt) = sum(u(:,nt).*(~anterior_idx{k})*dA);
        end
        nexttile (2*(k-1)-1)
        plot(0:0.01:1,[Q_ant;Q_ant(1)]*1e6, 'Color',color_m{n_case}, 'LineStyle','-.', LineWidth=2)
        hold on 
        ylim([-1.4,1.4])
            box on
    
    
        nexttile (2*(k-1))
        plot(0:0.01:1,[Q_post;Q_post(1)]*1e6, 'Color',color_m{n_case}, 'LineStyle','-.', LineWidth=2)
        hold on
        ylim([-1.4,1.4])
            box on

        Error_ant_i(k-1) = simps(tt, abs(Q_ant-Q_ant_pc))/simps(tt, abs(Q_ant_pc));
        Error_post_i(k-1) = simps(tt, abs(Q_post-Q_post_pc))/simps(tt, abs(Q_post_pc));
    end
    Error_ant{n_case} = Error_ant_i;
    Error_post{n_case} = Error_post_i;
        
end

yline(0, 'k:')

print(gcf, fullfile(pwd,'Figures', 'fig_9'), '-depsc','-vector');


%% 


figure('Color','w');
tiledlayout(n_slices-1, 1, 'TileSpacing','compact', 'Padding','compact');
set(gcf, 'Position', [100, 100, 200, 400]); % height scales with slices

cols = {blue, red};  % Your colors
names = {'(w/o)', "(L)"};

for k = 1:(n_slices-1)
    nexttile
    hold on

    % Gather anterior errors for this slice across cases
    vals = nan(1, numel(case_name));
    for i = 1:numel(case_name)
        if k <= numel(Error_ant{i})
            vals(i) = Error_ant{i}(k);
        end
    end

    % Create horizontal bar plot
    b = barh(vals, 'FaceColor', 'flat');
    for i = 1:numel(case_name)
        b.CData(i, :) = cols{i}; % Assign colors
    end

    % Adjust axes
    % xlim([0, max(vals)*1.2])
    ylim([0.5, numel(case_name)+0.5])
    set(gca, 'YTick', 1:numel(case_name), 'YTickLabel', names)
    % title(sprintf('Slice %d', k+1)) % since k=1 is slice 2
    box on
    xticks(0:0.2:1)
    xlim([0,0.5])
    if k == (n_slices-1)
        xlabel('$\int_0^T |\hat{Q} - Q|\,{\rm d}t \, / \, \int_0^T |Q|\,{\rm d}t$', 'Interpreter', 'latex', 'FontSize', fs)
    else
        xticklabels([])
    end
    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'off';
    set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
    set(gca, 'YDir', 'reverse')

end

print(gcf, fullfile(pwd,'Figures', 'fig_9_b'), '-depsc','-vector');


%% 
case_name = {"cl3_v1", "c0t"};


figure
tiledlayout(1,2, "TileSpacing", "loose", "Padding", "tight")
for k = 1:length(case_name)
    % === Load one case to get locations and indices ===
    case_i = case_name{k};
    [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_i);
    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
    data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    load(data_path, 'DNS');
    
    x = DNS.slices.x{sli};
    y = DNS.slices.y{sli};
    p = DNS.slices.p{sli};
    p0 = DNS.slices.p{1};
    
    nexttile
    scatter(x, y, 7, p(:,nt)-mean(p0(:,nt)), 'filled', 'square');
    colormap("jet")
    colorbar
    axis equal
    box on
end

function anterior_idx = plot_pressure(data, sli, ref, nt)
    x = data.x{sli};
    y = data.y{sli};
    p = data.p{sli};
    p0 = data.p{ref};
    Dp = p(:,nt)-mean(p0(:,nt));
    
    % scatter(x*1e2, y*1e2, 40, Dp, 'filled', 'square');
    xlabel("x [cm]", Interpreter="latex")
    ylabel("y [cm]", Interpreter="latex")
    colormap("jet")
    colorbar
    axis equal
    box on
    [val,idx]=min(y); % anterior region pixel
    anterior_idx = (sign(Dp) == sign(Dp(idx)));

    % scatter(x*1e2, y*1e2, 40, anterior_idx, 'filled', 'square');
end

function flow_rate_trans(Q, n)
    if Q(1) ~= Q(end)
        Q = [Q(:); Q(1)]';
    end
    if nargin == 1
        n = 0;
    end

    % Define color schemes
    blue = [116, 124, 187] / 255;  
    red  = [241, 126, 126] / 255;
    fs = 16;

    % Create a time vector
    t = linspace(0, 1, length(Q));
   
    % Plot the flow rate outline (black line)
    plot(t, Q, '-', 'LineWidth', 1.5, 'Color', [1,1,1]*0.7);
    % h.FaceAlpha = 0.1; % 30% opaque
    hold on;

    % Separate positive and negative flow rates for shading
    Q_neg = Q .* (Q < 0);

    % Area shading with transparency
    h1 = area(t, Q, 'FaceColor', red, 'EdgeColor', 'none');
    h1.FaceAlpha = 0.1; % 30% opaque

    h2 = area(t, Q_neg, 'FaceColor', blue, 'EdgeColor', 'none');
    h2.FaceAlpha = 0.1; % 30% opaque

    % Set axis properties
    set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', 10);

    % Highlight the specific point if n is greater than 0
    if n > 0
        xline(t(n+1), 'LineWidth', 1);
    end

    % Plot a horizontal line at y=0
    % plot(t, 0*t, '-', 'LineWidth', 1, 'Color', 'k');
    
    % Add labels if needed (optional)
    xlabel('$t/T$', 'Interpreter', 'latex', 'FontSize', fs);
    % ylabel('$Q\left[{\rm ml/s}\right]$', 'Interpreter', 'latex', 'FontSize', fs);
    ylim([-ceil(max(abs(Q))), ceil(max(abs(Q)))])

    hold off
end