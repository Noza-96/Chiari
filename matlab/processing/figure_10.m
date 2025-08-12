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

DY_fig = 400;

mesh_size = 0.0002;

fs = 16;
fan = 14;
ft = 12;

red   = [0.8, 0.2, 0.2];
green = [0.2, 0.6, 0.2];
blue  = [0.2, 0.4, 0.8];

sli = 3;

ntimes = [70];

case_name = ["c3", "cl3_v1"];

anterior_idx = cell(size(DNS.RMSE_space.x));

figure
tiledlayout(n_slices-1,2, "TileSpacing", "loose", "Padding", "tight");
set(gcf, 'Position',[100,100,500,DY_fig])
c_lim = {[-6.5,-3.5],[-8.2, -6.5],[-14.2,-12]};
% c_lim = {[-2.5,2.5],[-0.5,0.5],[-1.5,-1.5]};

for n_case = 1:length(case_name)

    % Localize anterior and posterior pixels
    [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name(n_case));
    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
    
    data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    load(data_path, 'DNS');

    for k = 2:n_slices
        for nt = ntimes 
            nexttile(2*(k-1)-2+n_case)
            plot_pressure(DNS.RMSE_space, k, 1, nt, true,'PlotType', 'contour', 'Mask', roi{k}, 'MaskXY', {x_roi{k}, y_roi{k}});
            caxis(c_lim{k-1});
    
            % Define ticks based on limit
            % cb_ticks = linspace(-c_lim(k-1), c_lim(k-1), 5);  % 5 evenly spaced ticks
            % cb = colorbar;
            % cb.Ticks = cb_ticks;
            % cb.TickDirection = 'out';  % optional
            % cb.FontSize = fan;          % match font size
            if n_case == 1
                ylabel('y [cm]', 'Interpreter','latex', FontSize=fs);
                % colorbar off
            end
            if k == n_slices
                xlabel('x [cm]', 'Interpreter','latex', FontSize=fs);
            end
        end
        if n_case == 2
            anterior_idx{k} = plot_pressure(DNS.RMSE_space, k, k, 30, false);
        end
    end
end
drawnow;

figure
scatter(DNS.RMSE_space.x{3}, DNS.RMSE_space.y{3}, 5, anterior_idx{3})

print(gcf, fullfile(pwd,'Figures', 'fig_10_pressure_lig'), '-depsc','-vector');

line_s = [':', '-'];

figure
tiledlayout(n_slices-1, 1, "TileSpacing", "compact", "Padding", "compact")
set(gcf, 'Position',[100,100,300,DY_fig])

% ant_c  = [1.00, 0.88, 0.40];  % warm yellow
% post_c = [0.55, 0.75, 0.88];  % soft blue
color_m = {blue, red};

tt = (0:(100-1))/(100);
line_sty = ["-.", "-"];

for n_case = 1:length(case_name)
    
    for k = 2:n_slices
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name{n_case});
        DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size) + version;
        data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
        load(data_path, 'DNS');

        pp = DNS.RMSE_space.p{k};
        p0 = DNS.RMSE_space.p{1};

        Nt = size(p0,2);
        Dp_ant = zeros(Nt, 1);
        Dp_post = zeros(Nt, 1);

        for n = 1:Nt
            Dp_ant(n) = sum((pp(:, n) - mean(p0(:, n))).*anterior_idx{k})/sum(anterior_idx{k});
            Dp_post(n) = sum((pp(:, n) - mean(p0(:, n))).*(~anterior_idx{k}))/sum(~anterior_idx{k});
        end

        nexttile (k-1)
        DP = Dp_ant-Dp_post;
        plot(0:0.01:1,[DP;DP(1)], 'Color',color_m{n_case}, 'LineStyle','-', LineWidth=1.5)
        % DP_ave = simps(0:0.01:0.99,DP);
        % mean(DP)
        hold on 
        % plot([0,1],[DP_ave, DP_ave], 'Color',color_m{n_case}, 'LineStyle',':', LineWidth=1.5)
        % plot(0:0.01:1,[Dp_post;Dp_post(1)], 'Color',post_c, 'LineStyle',line_sty(n_case), LineWidth=1.5)
        set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
        ylim([-1.5,2.5])
        xticks(0:0.2:1)
        box on

        if k < n_slices
            xticklabels([])
        else
            xlabel('$t/T$', 'Interpreter', 'latex', 'FontSize', fs);
        end

        if n_case == 1
            ylabel("$\Delta p^{({\rm a})}- \Delta p^{({\rm p})}$", 'Interpreter', 'latex', 'FontSize', fs);
        end

        yline(0, 'k:')
        xline(0.69, 'k--')
        box on
    end
    loc = cas.locations{k};

        
end


print(gcf, fullfile(pwd,'Figures', 'fig_10_p_t'), '-depsc','-vector');


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
        F = scatteredInterpolant(xs, ys, Ps, 'linear', 'nearest');  % or 'linear'
       
        % Define margins as 5% of data range
        x_margin = 0.3 * (max(x) - min(x));
        y_margin = 0.3 * (max(y) - min(y));
        
        % Extended grid limits
        xlin = linspace(min(x) - x_margin, max(x) + x_margin, gridsz(1));
        ylin = linspace(min(y) - y_margin, max(y) + y_margin, gridsz(2));  
        
        % xlin = linspace(min(x), max(x), gridsz(1));
        % ylin = linspace(min(y), max(y), gridsz(2));
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
