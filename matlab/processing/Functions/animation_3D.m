function animation_3D(cas, dat_PC, DNS)

    % 3D Animation for Velocity Output

    N0 = (DNS.cycles-1) * DNS.ts_cycle;
    tt = linspace(0, 1, DNS.ts_cycle);
    
    % animation settings
    azimuth = [-45, 0];
    elevation = [10, 5];
    opacity_val = 0.2;
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

    figure;
    tiledlayout(1, length(azimuth), "Padding", "loose", "TileSpacing", "loose");
    set(gcf, 'Position', [200, 100, 800, 800]);
        
    for n = 1:DNS.ts_cycle
        % Plot the velocity data from different views
        
            for k = 1:length(azimuth)
                nexttile(k);
                quiver3(x, y, z, u(:,n), v(:,n), w(:,n), sc);
                hold on;
                scatter3(X_mesh, Y_mesh, Z_mesh, 1, 'filled');
                alpha(opacity_val);

                view(azimuth(k), elevation(k));
                xlim(XL);
                ylim(YL);
                zlim(ZL);

                set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01]);
                xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', fs);
                ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', fs);
                zlabel('Z [cm]', 'Interpreter', 'latex', 'FontSize', fs);

                if k > 1
                    set(gca, 'YColor', 'none');
                    xlabel([]);
                end
                grid off;
                box off;    
                hold off;
                set(gca, 'Color', 'w');
            % Update the title for the current frame
            title(sprintf('$t/T = %.2f$', tt(n)), 'Interpreter', 'latex', 'FontSize', fs+4);
    
            % Save the current axis handle
            prev_ax = gca; % Save the current axis before switching
            load(fullfile(cas.dirmat, "bottom_velocity.mat"),'q');
            
            % Switch to ax1 and plot - to be completed
            ax1 = axes('Position', [0.35 0.25 0.15 0.10]);
            flow_rate(q, 0)
            ylim([-2,2])
            hold on 
            xline(n/100,LineWidth=1)
            hold off
            set(gca,"FontSize",8)
            ylabel("$Q\left[{\rm ml/s}\right]$",'interpreter','latex','FontSize',12)
            xlabel("$t/T$",'interpreter','latex','FontSize',12)
            hold off
       
            % Return to the previous axis after plotting in ax1
            axes(prev_ax);  % Restore the previous axis
            
            movieVector(n) = getframe(gcf);
        end
        drawnow;
         
    end

    % Save the animation as a video
    video_filename = "3D_velocity_animation";
    myWriter = VideoWriter(fullfile(cas.dirvid, video_filename));
    myWriter.FrameRate = 10;
    open(myWriter);
    writeVideo(myWriter, movieVector);
    close(myWriter);
end
