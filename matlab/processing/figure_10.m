clear; close all
subject = "s101_b";
mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
load(mri_data_path, 'cas', 'dat_PC');
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
pcmri = apply_roi_pcmri(pcmri);

load(fullfile(cas.dirmat,"DNS-results", "DNS_c0top_dx00002.mat"), 'DNS');
DNS_roi=DNS;
n_slices = length(DNS_roi.RMSE_space.x)-1;
x_roi = DNS_roi.slices.x;
y_roi = DNS_roi.slices.y;
roi = cell(1, n_slices);
for kk = 1:n_slices    
    roi{kk} = DNS_roi.slices.u_normal{kk}(:,1)==0;
end


mesh_size = 0.0002;

fs = 16;
fan = 14;
ft = 12;

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

sli = 3;

ntimes = [40,70,80];

% Localize anterior and posterior pixels
[t_geom, t_sim, b_inlet, version] = get_type_simulation("cl3_v1");
DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;

data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
load(data_path, 'DNS');

anterior_idx = cell(size(DNS.RMSE_space.x));

figure
tiledlayout(n_slices-1,length(ntimes), "TileSpacing", "loose", "Padding", "tight");
set(gcf, 'Position',[100,100,500,400])
c_lim = [2,0.3,0.8];

for k = 2:n_slices
    for nt = ntimes 
        nexttile
        plot_pressure(DNS.RMSE_space, k, k, nt, true,'PlotType', 'contour', 'Mask', roi{k}, 'MaskXY', {x_roi{k}, y_roi{k}});
        caxis([-c_lim(k-1) c_lim(k-1)]);

        % Define ticks based on limit
        cb_ticks = linspace(-c_lim(k-1), c_lim(k-1), 5);  % 5 evenly spaced ticks
        cb = colorbar;
        cb.Ticks = cb_ticks;
        cb.TickDirection = 'out';  % optional
        cb.FontSize = fan;          % match font size
        if nt ==40
            ylabel('y [cm]', 'Interpreter','latex', FontSize=fs);
        end
        if nt ~=80
            colorbar off
        end
        if k == n_slices
            xlabel('x [cm]', 'Interpreter','latex', FontSize=fs);
        end
    end
    anterior_idx{k} = plot_pressure(DNS.RMSE_space, k, k, 30, false);

end
drawnow;

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

function [anterior_idx, X, Y, P] = plot_pressure(data, sli, ref, nt, do_plot, varargin)
% Optional name-value:
%   'GridSize' [nx ny]  (default [200 200])
%   'MaxPts'   Nmax     (default 1e5)
%   'PlotType' 'contour' (default) or 'scatter'
%   'Mask'     logical vector same length as data.x{sli}
%   'MaskXY'   {x_raw, y_raw} raw coords (same length as Mask), if different from data.x/y

    if nargin < 5 || isempty(do_plot)
        do_plot = true;
    end

    fan = 14;

    ip = inputParser;
    ip.addParameter('GridSize', [200 200]);
    ip.addParameter('MaxPts', 1e5);
    ip.addParameter('PlotType', 'contour');
    ip.addParameter('Mask', []);
    ip.addParameter('MaskXY', []);
    ip.parse(varargin{:});
    gridsz   = ip.Results.GridSize;
    Nmax     = ip.Results.MaxPts;
    plotType = lower(ip.Results.PlotType);
    roi_mask = ip.Results.Mask;
    maskXY   = ip.Results.MaskXY;

    % Data
    x  = data.x{sli};
    y  = data.y{sli};
    pp = data.p{sli};
    p0 = data.p{ref};
    Dp = pp(:, nt) - mean(p0(:, nt));

    % anterior_idx (pointwise)
    [~, idx_min_y] = min(y);
    anterior_idx   = (sign(Dp) == sign(Dp(idx_min_y)));

    % Try fast path (reshape)
    nx = numel(unique(x));
    ny = numel(unique(y));
    did_fast = false;
    if nx * ny == numel(x)
        try
            X = reshape(x, ny, nx);
            Y = reshape(y, ny, nx);
            P = reshape(Dp, ny, nx);
            did_fast = true;
        catch
        end
    end

    % Fallback interpolation
    if ~did_fast
        npts = numel(x);
        if npts > Nmax
            idx = randperm(npts, Nmax);
            xs = x(idx); ys = y(idx); Ps = Dp(idx);
        else
            xs = x; ys = y; Ps = Dp;
        end
        F = scatteredInterpolant(xs, ys, Ps, 'linear', 'none');
        xlin = linspace(min(x), max(x), gridsz(1));
        ylin = linspace(min(y), max(y), gridsz(2));
        [X, Y] = meshgrid(xlin, ylin);
        P = F(X, Y);
    end

    % Plot if requested
    if do_plot
        switch plotType
            case 'contour'
                contourf(X*1e2, Y*1e2, P, 100, 'LineColor', 'none');
            case 'scatter'
                scatter(x*1e2, y*1e2, 40, Dp, 'filled', 's');
        end

        colormap('jet'); colorbar; box on;

        % ==== ROI overlay (choose ONE of the two approaches below) ====

        % --- A) Point-boundary overlay (no grid needed) ---
        if ~isempty(roi_mask)
            if ~isempty(maskXY)
                x_raw = maskXY{1}; y_raw = maskXY{2};
            else
                x_raw = x; y_raw = y;
            end
            x_roi = x_raw(roi_mask) * 1e2;   % cm
            y_roi = y_raw(roi_mask) * 1e2;
            if ~isempty(x_roi)
                hold on
                % Tight boundary polygon; tweak shrink factor (0..1) if needed
                try
                    k = boundary(x_roi, y_roi, 0.9);
                    plot(x_roi, y_roi, 'k.', 'LineWidth', 1.2);
                catch
                    plot(x_roi, y_roi, 'k.', 'MarkerSize', 4);
                end
                hold off
            end
        end

        % Set axis limits and properties
        Dx = max(x*1e2) - min(x*1e2);
        Dy = max(y*1e2) - min(y*1e2);
        xlim([min(x*1e2) - 0.1 * Dx, max(x*1e2) + 0.1 * Dx]);
        ylim([min(y*1e2) - 0.1 * Dy, max(y*1e2) + 0.1 * Dy]);
        set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
        box on;


        % --- B) Grid-contour overlay (clean outline matching your contour grid) ---
        % If you prefer a clean contour line at the ROI boundary, uncomment:
        %{
        if ~isempty(roi_mask)
            if ~isempty(maskXY)
                x_raw = maskXY{1}; y_raw = maskXY{2};
            else
                x_raw = x; y_raw = y;
            end
            Interpolate logical mask to grid (as double), then draw 0.5 contour
            Fm = scatteredInterpolant(x_raw, y_raw, double(roi_mask), 'nearest', 'nearest');
            Mq = Fm(X, Y);
            hold on
            contour(X*1e2, Y*1e2, Mq, [0.5 0.5], 'k-', 'LineWidth', 1.2);
            hold off
        end
        %}
    end
end
