clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')

subject = "s101_a";
case_name = {"cn2", "c2", "c1b", "c0t"};
mesh_size = [0.0002];

fs = 16;
fan = 10;
rows = 3;


% Load MRI data
mri_data_path = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
load(mri_data_path, 'cas');
load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');

t = linspace(0, 1, pcmri.Nt);
Ncases = length(case_name);
colors = lines(Ncases);  % Unique colors per case


for i = 1:Ncases
    case_i = case_name{i};
    [t_geom, t_sim, b_inlet] = get_type_simulation(case_i);
    DNS_case = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size);
    data_path = fullfile(cas.dirmat, "DNS-results", "DNS_" + DNS_case + ".mat");
    load(data_path, 'DNS');
    st_DNS{i} = DNS;
    if ~exist(data_path, 'file')
        fprintf(2, 'File "%s" does not exist, simulation needs to be done \n', "DNS_" + DNS_case + ".mat");
        return
    end
    if t_sim==1
        DNS_roi=DNS;
    elseif t_geom == "cn"
        DNS_roi_n=DNS;
        index_n = i;
    end
end

Ndat = pcmri.Ndat;
% === Plotting ===
%-----
x_roi =DNS_roi.slices.x;
y_roi = DNS_roi.slices.y;
x_roi_n =DNS_roi_n.slices.x;
y_roi_n = DNS_roi_n.slices.y;
roi = cell(1,Ndat);
for kk = 1:Ndat    
    roi{kk} = DNS_roi.slices.u_normal{kk}(:,1)==0;
    roi_n{kk} = DNS_roi_n.slices.u_normal{kk}(:,1)==0;
end
    
fig = figure('Position', [100, 100, 150*(Ncases), 450]);
tt=tiledlayout(Ndat, Ncases , "TileSpacing", "tight", "Padding", "compact");
title(tt, '$\overline{\mathrm{RMSE}}$', 'FontSize', fs, 'interpreter', 'latex');  % Title for the whole tiled layout

for loc = 1:Ndat           
    % Plot PC-MRI data/results
    for kk = 1:Ncases
        spatial_error_plot(st_DNS{kk}.RMSE_space, st_DNS{kk}.case, loc, Ndat, kk + (Ncases)*(loc-1), Ncases, roi{loc}, x_roi{loc}, y_roi{loc}); 
    end
end

print(gcf, fullfile(pwd,'Figures', subject+'_fig_2_b'), '-depsc','-vector');

%% auxiliary functions
function spatial_error_plot(data, name_loc, loc, Ndat, ii, Ncases, roi_mask, x_raw, y_raw)
    fs = 12;
    % Extract data and rescale
    x = data.x{loc} * 1e2; % [cm]
    y = data.y{loc} * 1e2; % [cm]
    w = data.val{loc} * 1e2; % [cm/s]

    % Plot in the specified tile
    nexttile(ii);
    scatter(x, y, 10, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    colormap('parula');       % or 'parula', etc.
    caxis([0 2]);  % set the color limits
    % bluetored(6);

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
    box on;
    % if n==1 && ii == 1 + (Ncases+1)*(loc-1) 
    %     named_location (gca, data.locations{loc}, fs)
    % end
    if ii ~= Ncases 
            colorbar off;
    end
    % if ii <= Ncases
    %     sstt = char(name_loc);  % Assuming 'data.case' is a string
    %     if ~strcmp(sstt, 'PC-MRI')  % Use strcmp to compare strings
    %          if ismember(sstt(3), ['b', 't'])
    %             sstt = extractBetween(sstt, 1, 3);
    %         else
    %             sstt = extractBetween(sstt, 1, 2);
    %         end
    %         sstt = sstt + " DNS";
    %     end
    %     title(sstt)
    % end
    if ii == 1 + (Ncases+1)*(loc-1)
        ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
    else
        ylabel('');
    end

    if loc == Ndat
        xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
    end
     xlabel('');
     ylabel('');
     xticks([])
     yticks([])
    set(gcf, 'Color', 'w')

    

if exist('roi_mask', 'var') && ~isempty(roi_mask)
    hold on

    % Extract ROI points
    x_roi_pts = x_raw(roi_mask) * 1e2;  % [cm]
    y_roi_pts = y_raw(roi_mask) * 1e2;

    % Use boundary to extract the outer contour of the ROI points
    if ~isempty(x_roi_pts)
        try
            plot(x_roi_pts, y_roi_pts, 'k', 'Marker', '.', 'LineStyle', 'none', 'MarkerSize', 2);
        catch
            % fallback if boundary fails
            plot(x_roi_pts, y_roi_pts, 'k.');
        end
    end

    hold off
end


end

function named_location (gca, sstt, fs)
        % Get the position of the current tile (in normalized figure coordinates)
    ax = gca;  % Get the current axis handle
    axPos = ax.Position;  % Position of the axis [left, bottom, width, height]

    % Compute normalized figure coordinates for the top-left corner of the tile
    % Axes position is in normalized figure coordinates [0, 1], so adjust for annotation
    xPos = axPos(1);  % X position of the tile
    yPos = axPos(2) + axPos(4) ;  % Slightly offset from the top (5% from the top edge of the tile)
    width = 0.2 * axPos(3);  % Width of the textbox (20% of the tile's width)
    height = 0.05 * axPos(4);   % Height of the textbox (5% of figure height)

    % Position it in the top-left corner of the tile using normalized figure coordinates
   dim = [xPos, yPos, width, height];
    
    % Create the textbox
    annotation('textbox', dim, 'String', sstt, 'FontSize', fs, 'Color', 'black', ...
               'EdgeColor', 'none', 'BackgroundColor', 'none', 'Interpreter', 'latex');
end



function plot_flow_rate(q,n)
    prev_ax = gca; % Save the current axis before switching
    
    % Switch to ax1 and plot - to be completed
    ax1 = axes('Position', [0.15 0.12 0.08 0.04]);
    flow_rate(q, 0)
    % ylim([-2,2])
    hold on 
    xline(n/100,LineWidth=1)
    set(gca,"FontSize",8)
    ylabel(''); xticks('');
    xlabel(''); yticks('');
    hold off
    % Return to the previous axis after plotting in ax1
    axes(prev_ax);  % Restore the previous axis
    drawnow;

end