% Velocity fields
clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/')
subjects = {"s101_b", "s101_a", "s101_aa"};
% subjects = {"s101_b"};
frame_idx = [1,26,51,76];

% Set up figure properties
figure;
set(gcf, 'Position', [200, 200, 250*length(frame_idx), 300*length(subjects)]);
tiledlayout(length(subjects), length(frame_idx), "TileSpacing", "none", "Padding", "none");
% colormap turbo;

ftit = 16;
fs = 12;
fan = 10;

u_max = [6,14,6];
t = linspace(0,1,100);

max_c = [4,6,10,10];

for s=1:length(subjects)
subject = subjects{s};
% u_max = 0;
    for j = 1:length(frame_idx)
        frame = frame_idx(j);
        nexttile
        file_location = fullfile("../../../computations", "pc-mri", subject, "mat","04-registration.mat"); 
        if exist(file_location) == 0
            continue
        end
            load(file_location, 'cas', 'dat_PC');
            load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
            load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');
            stl_path = fullfile(cas.dirseg, 'stl', 'clip_segmentation.stl');

        zl = [100,-100];
        for i = 1:pcmri.Ndat
            % Coordinates
            x = pcmri.x{i}*1e3;
            y = pcmri.y{i}*1e3;
            z = pcmri.z{i}*1e3;
            z = z-anatomy.FM;
        
            % Velocity magnitude at each point over time (average over time)
            u = pcmri.u_normal{i};              % size: [npts x Nt]
             
            % Plot colored points
            u_frame = u(:, frame) * 100;

            % Separate nonzero and zero indices
            nonzero_idx = abs(u_frame) >= 0.01;
            zero_idx = u_frame == 0;
            
            % Plot zero-velocity points in gray
            hold on;

            plot_stl_surface(stl_path, -anatomy.FM)

            % Plot nonzero-velocity points with colormap
            scatter3(x(nonzero_idx), y(nonzero_idx), z(nonzero_idx), 8, u_frame(nonzero_idx), 'filled');
            % scatter3(x(zero_idx), y(zero_idx), z(zero_idx), 8, [0.7 0.7 0.7], 'filled');

            % Optional: label location
            % text(mean(x), mean(y), mean(z), pcmri.locations{i}, 'FontSize', 12, 'Color', 'w');
            % u_max = max(u_max, max(abs(u_frame)));
            zl = [min(floor(min(z)*10)/10, zl(1)), max(ceil(max(z)*10)/10,zl(2))];
        end
        
        set(gca, 'LineWidth', 1, 'TickLength', [0.002 0.002], 'FontSize', fan);
        set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.2);  % light gray, semi-transparent
        bluetored(max(ceil(abs(u_frame)),4));
        bluetored(max_c(j));
        set(gcf, 'Color', 'w');
        colorbar off;
        box on
        grid off
        axis off
        % zlim(zl)
        axis equal;


        % text(0.5, 1.04, "$t/T=" + floor(t(frame)*100)/100 + "$", 'Units','normalized', 'HorizontalAlignment','center',...
                 % 'Interpreter','latex', 'FontSize',ftit, 'BackgroundColor','w', 'Margin',4, 'EdgeColor','k', 'LineWidth',0.8);


        % xticks(-100:10:100)
        % yticks(-100:10:100)
        % zticks(-100:10:100)
        % 
        % if s == 1
        %     str = "$t/T=" + floor(t(frame)*100)/100 + "$";
        %     text(0.5, 1.12, "$t/T=" + floor(t(frame)*100)/100 + "$", 'Units','normalized', 'HorizontalAlignment','center',...
        %         'Interpreter','latex', 'FontSize',ftit, 'BackgroundColor','w', 'Margin',4, 'EdgeColor','k', 'LineWidth',0.8);
        % end
        % 
        % if frame == frame_idx(1)
        %         xlabel('$x \,[{\rm mm}]$','Interpreter','latex','FontSize',fs);
        %         ylabel('$y \,[{\rm mm}]$','Interpreter','latex','FontSize',fs);
        %         zlabel('$z \,[{\rm mm}]$','Interpreter','latex','FontSize',fs);
        % 
        % else
        %     xticklabels([]);
        %     yticklabels([]);
        %     zticklabels([]);
        % end
        if frame == frame_idx(end)
                hcb=colorbar('eastoutside');
                % Make the colorbar smaller
                pos = get(hcb, 'Position');       % [left bottom width height]
                pos(2) = pos(2) + 0.2 * pos(4);   % shift upward
                pos(4) = 0.6 * pos(4);            % reduce height
                set(hcb, 'Position', pos);
                colorbar off
        end
        % colorbar;
        view (3)
        % grid on;
    end
end

% saveas(gcf,fullfile(pwd,'Figures', 'fig_2'),'png')

% print(gcf, fullfile(pwd,'Figures', 'fig_2'), '-depsc','-vector');

function plot_stl_surface(stl_path, Dz)
    if exist(stl_path, 'file') ~= 2
        warning('STL file not found: %s', stl_path);
        return;
    end

    % Read STL (returns a triangulation object)
    tri = stlread(stl_path);
    f = tri.ConnectivityList;
    v = tri.Points;  % [mm]

    % Apply translation in z-direction
    v(:,3) = v(:,3) + Dz;

    hold on;
    patch('Faces', f, 'Vertices', v, ...
          'FaceColor', [0.8 0.8 0.8], ...
          'EdgeColor', 'none', ...
          'FaceAlpha', 0.15);
end
