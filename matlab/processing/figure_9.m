clear; close all
subject = "s101_b";
mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
load(mri_data_path, 'cas', 'dat_PC');
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
pcmri = apply_roi_pcmri(pcmri);

mesh_size = 0.0002;

modes = 20; 

fs = 16;
fan = 14;
ft = 12;

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

orange = [230, 159,   0] / 255;   % #E69F00
teal   = [  0, 158, 115] / 255;   % #009E73

color_ant_canal = [255, 255, 204]/255;
color_post_canal = [204, 255, 255]/255;

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


color_m = {orange, teal};

% color_m = {blue, red};
tt = (0:(100-1))/(100);

Error_ant_i = zeros(1,n_slices-1);
Error_post_i = zeros(1,n_slices-1);

Error_ant = cell(1,length(case_name));
Error_post = cell(1,length(case_name));

%% Preallocate (as you had)
Vs_post = zeros(n_slices, 1);
Vs_ant  = zeros(n_slices, 1);
Vs_tot  = zeros(n_slices, 1);
A_post  = zeros(n_slices, 1);
A_ant   = zeros(n_slices, 1);

Error_ant = cell(numel(case_name),1);
Error_post = cell(numel(case_name),1);

%% ---------- Figure 1: ANTERIOR ----------
figA = figure;
tla  = tiledlayout(n_slices-1, 1, "TileSpacing","compact", "Padding","compact");
set(figA, 'Position',[100,100,200,400])

for n_case = 1:length(case_name)
    Error_ant_i = zeros(n_slices-1,1);

    for k = 2:n_slices
        % ==== PC-MRI ====
        u_pc = pcmri.u_normal{k};
        Nt   = size(u_pc,2);
        Q_ant_pc  = zeros(Nt,1);
        Q_post_pc = zeros(Nt,1);
        Q_tot_pc  = zeros(Nt,1);

        for nt = 1:Nt
            Q_ant_pc(nt)  = sum(u_pc(:,nt).* anterior_idx{k}   * dA);
            Q_post_pc(nt) = sum(u_pc(:,nt).*(~anterior_idx{k}) * dA);
            Q_tot_pc (nt) = sum(u_pc(:,nt) * dA);
        end

        % stroke volumes (ml); T is the cardiac period at this slice
        Tslice = dat_PC.T{k};
        Vs_tot(k)  = 0.5 * simps(tt*Tslice, abs(Q_tot_pc )) * 1e6;
        Vs_ant(k)  = 0.5 * simps(tt*Tslice, abs(Q_ant_pc )) * 1e6;
        Vs_post(k) = 0.5 * simps(tt*Tslice, abs(Q_post_pc)) * 1e6;

        % smooth
        [Q_tot_pc,  ~,~,~] = four_approx(Q_tot_pc,  modes, 0, 100);
        [Q_ant_pc,  ~,~,~] = four_approx(Q_ant_pc,  modes, 0, 100);
        [Q_post_pc, ~,~,~] = four_approx(Q_post_pc, modes, 0, 100);

        % areas (cm^2)
        A_ant(k)  = sum( anterior_idx{k})   * dA * 1e4;
        A_post(k) = sum(~anterior_idx{k})   * dA * 1e4;

        % Background (only once): anterior PC-MRI
        ax = nexttile(k-1);
        if n_case == 1
            flow_rate_trans(Q_ant_pc*1e6, color_ant_canal); hold on
            if k < n_slices, xticklabels([]); xlabel([]); end
            set(ax, 'LineWidth',1, 'TickLength',[0.01 0.01], 'FontSize', fan);
            ylabel('$Q_{\rm ant}(t)$', 'Interpreter','latex', 'FontSize', fs);
            xlabel([])
            % xlabel('$\frac{\int_0^T |\hat{Q}_{\rm post} - Q_{\rm post}|\,{\rm d}t}{\int_0^T |Q_{\rm post}|\,{\rm d}t}$', 'Interpreter', 'latex', 'FontSize', fs)
            % annotations
            xPos = 0.05; yPos = -1.1; Dy = 0.35;
            if k == 2
                text(xPos, yPos,    "$V_{s,\rm ant} = " + round(Vs_ant(k),2) + "\,{\rm ml}$", 'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
                text(xPos, yPos+Dy, "$A_{\rm ant} = "  + round(A_ant(k),2)  + "\,{\rm cm}^2$", 'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
            else
                text(xPos, yPos,    "$ " + round(Vs_ant(k),2) + "\,{\rm ml}$",     'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
                text(xPos, yPos+Dy, "$"  + round(A_ant(k),2)  + "\,{\rm cm}^2$",   'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
            end
        else
            hold(ax,'on');
        end

        % ==== DNS for current case ====
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{n_case});
        DNS_case  = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        load(data_path, 'DNS');

        u_sim = DNS.RMSE_space.u_normal{k};
        Nt    = size(u_sim,2);
        Q_ant = zeros(Nt,1);
        for nt = 1:Nt
            Q_ant(nt) = sum(u_sim(:,nt).* anterior_idx{k} * dA);
        end
        [Q_ant, ~,~,~] = four_approx(Q_ant, modes, 0, 100);
    
        % overlay DNS
        plot(linspace(0,1,101), [Q_ant, Q_ant(1)]*1e6, ...
             'Color', color_m{n_case}, 'LineStyle','-', 'LineWidth',1.5);
        ylim([-1.4, 1.4]); yticks([-1 0 1]); box on

        % error (anterior)
        Error_ant_i(k-1) = simps(tt, abs(Q_ant - Q_ant_pc)) / simps(tt, abs(Q_ant_pc));
    end

    Error_ant{n_case} = Error_ant_i;
end

% zero-line on all tiles
axs = findall(figA, 'Type','axes');
for ax = axs', yline(ax, 0, 'k:'); end

print(figA, fullfile(pwd,'Figures','fig_9_anterior'), '-depsc','-vector');

%% ---------- Figure 2: POSTERIOR ----------
figP = figure;
tlp  = tiledlayout(n_slices-1, 1, "TileSpacing","compact", "Padding","compact");
set(figP, 'Position',[500,100,200,400])

for n_case = 1:length(case_name)
    Error_post_i = zeros(n_slices-1,1);

    for k = 2:n_slices
        % ==== PC-MRI ====
        u_pc = pcmri.u_normal{k};
        Nt   = size(u_pc,2);
        Q_ant_pc  = zeros(Nt,1);
        Q_post_pc = zeros(Nt,1);
        Q_tot_pc  = zeros(Nt,1);

        for nt = 1:Nt
            Q_ant_pc(nt)  = sum(u_pc(:,nt).* anterior_idx{k}   * dA);
            Q_post_pc(nt) = sum(u_pc(:,nt).*(~anterior_idx{k}) * dA);
            Q_tot_pc (nt) = sum(u_pc(:,nt) * dA);
        end

        % stroke volumes (ml)
        Tslice = dat_PC.T{k};
        Vs_tot(k)  = 0.5 * simps(tt*Tslice, abs(Q_tot_pc )) * 1e6;
        Vs_ant(k)  = 0.5 * simps(tt*Tslice, abs(Q_ant_pc )) * 1e6;
        Vs_post(k) = 0.5 * simps(tt*Tslice, abs(Q_post_pc)) * 1e6;

        % smooth
        [Q_tot_pc,  ~,~,~] = four_approx(Q_tot_pc,  modes, 0, 100);
        [Q_ant_pc,  ~,~,~] = four_approx(Q_ant_pc,  modes, 0, 100);
        [Q_post_pc, ~,~,~] = four_approx(Q_post_pc, modes, 0, 100);

        % areas (cm^2)
        A_ant(k)  = sum( anterior_idx{k}) * dA * 1e4;
        A_post(k) = sum(~anterior_idx{k}) * dA * 1e4;

        % Background (only once): posterior PC-MRI
        ax = nexttile(k-1);
        if n_case == 1
            flow_rate_trans(Q_post_pc*1e6, color_post_canal); hold on
            if k < n_slices, xticklabels([]); xlabel([]); end
            xlabel([])
            set(ax, 'LineWidth',1, 'TickLength',[0.01 0.01], 'FontSize', fan);
            ylabel('$Q_{\rm post}(t)$', 'Interpreter','latex', 'FontSize', fs);

            % annotations
            xPos = 0.05; yPos = -1.1; Dy = 0.35;
            if k == 2
                text(xPos, yPos,    "$V_{s,\rm post} = " + round(Vs_post(k),2) + "\,{\rm ml}$", 'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
                text(xPos, yPos+Dy, "$A_{\rm post} = "  + round(A_post(k),2)  + "\,{\rm cm}^2$", 'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
            else
                text(xPos, yPos,    "$ " + round(Vs_post(k),2) + "\,{\rm ml}$",       'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
                text(xPos, yPos+Dy, "$"  + round(A_post(k),2)  + "\,{\rm cm}^2$",     'Interpreter','latex','Color',[1,1,1]*0.1,'FontSize',ft,'FontWeight','bold');
            end
        else
            hold(ax,'on');
        end

        % ==== DNS for current case ====
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{n_case});
        DNS_case  = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        load(data_path, 'DNS');

        u_sim = DNS.RMSE_space.u_normal{k};
        Nt    = size(u_sim,2);
        Q_post = zeros(Nt,1);
        for nt = 1:Nt
            Q_post(nt) = sum(u_sim(:,nt).*(~anterior_idx{k}) * dA);
        end
        [Q_post, ~,~,~] = four_approx(Q_post, modes, 0, 100);

        % overlay DNS
        plot(linspace(0,1,101), [Q_post, Q_post(1)]*1e6, ...
             'Color', color_m{n_case}, 'LineStyle','-', 'LineWidth',1.5);
        ylim([-1.4, 1.4]); yticks([-1 0 1]); box on

        % error (posterior)
        Error_post_i(k-1) = simps(tt, abs(Q_post - Q_post_pc)) / simps(tt, abs(Q_post_pc));
    end

    Error_post{n_case} = Error_post_i;
end

% zero-line on all tiles
axs = findall(figP, 'Type','axes');
for ax = axs', yline(ax, 0, 'k:'); end

print(figP, fullfile(pwd,'Figures','fig_9_posterior'), '-depsc','-vector');


%% 

cols = {orange, teal};  % Your colors
names = {'(w/o)', "(L)"};

XL = [0.4;0.6];
for zon = 1:2
    figure('Color','w');
    tiledlayout(n_slices-1, 1, 'TileSpacing','compact', 'Padding','compact');
    set(gcf, 'Position', [100, 100, 120, 400]); % height scales with slices

    if zon == 1
        Err = Error_ant;
    else
        Err = Error_post;
    end

    for k = 1:(n_slices-1)
        nexttile
        hold on
    
        % Gather anterior errors for this slice across cases
        vals = nan(1, numel(case_name));
        for i = 1:numel(case_name)
            if k <= numel(Err{i})
                vals(i) = Err{i}(k);
            end
        end
    
        % Create horizontal bar plot
        b = barh(vals, 'FaceColor', 'flat', 'BarWidth', 0.5, 'LineWidth', 1.);
        for i = 1:numel(case_name)
            b.CData(i, :) = cols{i}; % Assign colors
        end
    
        yticklabels([])
        yticks([]) 
        ylim([0.5, numel(case_name)+0.5]) 
        box on
        xticks([0,XL(zon)/2,XL(zon)])
        xlim([0,XL(zon)])
        xlabel([])
        if k == (n_slices-1)
            % xlabel('$\int_0^T |\hat{Q} - Q|\,{\rm d}t \, / \, \int_0^T |Q|\,{\rm d}t$', 'Interpreter', 'latex', 'FontSize', fs)
        else
            xticklabels([])
        end
        xlabel([])
        ax = gca;
        ax.XGrid = 'off';
        ax.YGrid = 'off';
        set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
        set(gca, 'YDir', 'reverse')
    
    end
    
    print(gcf, fullfile(pwd,'Figures', "fig_9_b_"+zon), '-depsc','-vector');
end

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
    
    [val,idx]=min(y); % anterior region pixel
    anterior_idx = (sign(Dp) == sign(Dp(idx)));

    % scatter(x*1e2, y*1e2, 40, anterior_idx, 'filled', 'square');
end

function flow_rate_trans(Q, color_m)
    if Q(1) ~= Q(end)
        Q = [Q(:); Q(1)]';
    end
    n=0;

    % Define color schemes
    % blue = [116, 124, 187] / 255;  
    % red  = [241, 126, 126] / 255;
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
    h1 = area(t, Q, 'FaceColor', color_m, 'EdgeColor', 'none');
    h1.FaceAlpha = 0.5; % 30% opaque

    h2 = area(t, Q_neg, 'FaceColor', color_m, 'EdgeColor', 'none');
    h2.FaceAlpha = 0.5; % 30% opaque

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