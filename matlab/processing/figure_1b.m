clear; close all; clc;
addpath('Functions/');
addpath('Functions/Others/');

subjects = {"s101_b", "s101_a", "s101_aa"};
frame_idx = [41, 66, 81];
t_T= [0.4, 0.65, 0.8];

% Export options
out_path = fullfile(pwd, 'Figures');
if ~exist(out_path, 'dir'), mkdir(out_path); end

ftit = 16; fs = 12; fan = 10;
max_c = [8, 8, 8];

for s = 1:length(subjects)
    subject = subjects{s};

    % === New figure per subject ===
    fig_vel = figure;
    set(fig_vel, 'Position', [200, 200, 250 * length(frame_idx), 330]);
    t2 = tiledlayout(1, length(frame_idx), "TileSpacing", "none", "Padding", "none");

    for j = 1:length(frame_idx)
        frame = frame_idx(j);
        nexttile(t2);
        view(3);

        file_location = fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat");
        if ~exist(file_location, 'file'), continue; end

        load(file_location, 'cas', 'dat_PC');
        load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
        load(fullfile(cas.dirmat, "anatomical_locations.mat"), 'anatomy');

        % === Plot STL ===
        stl_path = fullfile(cas.dirseg, 'stl', 'clip_segmentation.stl');
        hold on;

        for i = 1:pcmri.Ndat
            x = pcmri.x{i} * 1e3;
            y = pcmri.y{i} * 1e3;
            z = pcmri.z{i} * 1e3 - anatomy.FM;
            u = pcmri.u_normal{i};
            u_frame = u(:, frame) * 100;

            nonzero_idx = abs(u_frame) >= 0.01;
            x_nz = x(nonzero_idx); y_nz = y(nonzero_idx); z_nz = z(nonzero_idx);
            u_nz = u_frame(nonzero_idx);

            xq = linspace(min(x_nz), max(x_nz), 80);
            yq = linspace(min(y_nz), max(y_nz), 80);
            [Xq, Yq] = meshgrid(xq, yq);
            Uq = griddata(x_nz, y_nz, u_nz, Xq, Yq, 'natural');
            Zq = mean(z_nz) * ones(size(Xq));

            surf(Xq, Yq, Zq, Uq, 'EdgeColor', 'none');
            shading interp;
        end

        axis equal off;
        set(gca, 'FontSize', fan, 'SortMethod', 'childorder');
        bluetored(max_c(j));
        plot_stl_surface(stl_path, -anatomy.FM);
        % title("$t/T = " +num2str(t_T(j))+"$", 'Interpreter', 'latex', 'FontSize', ftit);

        % Optional: Add colorbar only on last tile
        if j == length(frame_idx)
            hcb = colorbar('eastoutside');
            pos = get(hcb, 'Position');
            pos(2) = pos(2) + 0.2 * pos(4);
            pos(4) = 0.6 * pos(4);
            set(hcb, 'Position', pos);
        end
        colorbar off
    end

    % === Save each subject figure ===
    print(fig_vel, fullfile(out_path, "fig_velocity_" + subject), '-dpng', '-r600');
    close(fig_vel);
end

%% === Function: Plot STL surface ===
function plot_stl_surface(stl_path, Dz)
    if exist(stl_path, 'file') ~= 2
        warning('STL file not found: %s', stl_path);
        return;
    end
    tri = stlread(stl_path);
    f = tri.ConnectivityList;
    v = tri.Points;
    v(:, 3) = v(:, 3) + Dz;

    [fr, vr] = reducepatch(f, v, 0.1);
    patch('Faces', fr, 'Vertices', vr, ...
        'FaceColor', [0.5 0.5 0.5], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.08);
end