function animation_3D(cas, dat_PC, DNS)

    % 3D Animation for Velocity Output
    
    % animation settings
    azimuth = -45;
    % azimuth = [-45, 0];
    elevation = [10];
    opacity_val = 0.1;
    fs = 10; % fontsize
    sc = 5; % Scale factor for velocity vectors

    % Load mesh data
    meshID = fopen(fullfile(cas.diransys_out,"surface_mesh"), 'r');
    Mesh = textscan(meshID, '%d %f %f %f', 'HeaderLines', 3);
    X_mesh = Mesh{2} * 100;
    Y_mesh = Mesh{3} * 100;
    Z_mesh = Mesh{4} * 100;
    fclose(meshID);

    % Set plot limits
    XL = [min(X_mesh(:)) - 0.2, max(X_mesh(:)) + 0.2];
    YL = [min(Y_mesh(:)) - 0.2, max(Y_mesh(:)) + 0.2];
    ZL = [min(Z_mesh(:)) - 0.5, max(Z_mesh(:)) + 0.5];
    
    % load the variables from the slices and concatenate them
    x = vertcat(DNS.slices.x{1:dat_PC.Ndat}) * 100;
    y = vertcat(DNS.slices.y{1:dat_PC.Ndat}) * 100;
    z = vertcat(DNS.slices.z{1:dat_PC.Ndat}) * 100;
    u = vertcat(DNS.slices.u{1:dat_PC.Ndat}) * 100;
    v = vertcat(DNS.slices.v{1:dat_PC.Ndat}) * 100;
    w = vertcat(DNS.slices.w{1:dat_PC.Ndat}) * 100;

    load(fullfile(cas.dirmat, "bottom_velocity.mat"),'q');

    figure;
    set(gcf, 'Position', [200, 100, 400, 800], 'Color', 'w');
    % Main plot (3D quiver)
    main_axis = axes; % Define main axis before the loop

    % Create ax1 (inset) only once
    ax1 = axes('Position', [0.25 0.25 0.2 0.08], 'Box', 'on', 'Color', 'w');
    flow_rate(q, 0);
    ylim([-2,2]);
    ylabel("$Q\left[{\rm ml/s}\right]$", 'interpreter', 'latex', 'FontSize', fs);
    xlabel("$t/T$", 'interpreter', 'latex', 'FontSize', fs);

    for n = 1:DNS.ts_cycle
        axes(main_axis); 
        quiver3(x, y, z, u(:,n), v(:,n), w(:,n), sc);
        hold on;
        scatter3(X_mesh, Y_mesh, Z_mesh, 1, 'filled');
        alpha(opacity_val);
        set(gca,'LineWidth', 1, 'TickLength', [0.01 0.01]);
        xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        zlabel('Z [cm]', 'Interpreter', 'latex', 'FontSize', fs);
        xlim(XL); ylim(YL); zlim(ZL);
        view(azimuth,elevation)
        grid off; box off; 
        hold off;
    
        % Switch to ax1 and update the flow plot
        axes(ax1);
        h = xline(n/DNS.ts_cycle, 'k', 'LineWidth', 1); % time
    
        movieVector(n) = getframe(gcf);
        drawnow;  

        delete(h); % Remove the previous xline
        % Return to main axis
    end

    % Save the animation as a video
    video_filename = fullfile(cas.dirvid,"3D_velocity_animation_"+DNS.case);
    save_animation(movieVector, video_filename)
end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
end