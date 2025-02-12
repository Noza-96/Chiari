function comparison_results(cas, data_a, case_b, case_c, case_d)

    if nargin > 2
    load(fullfile(cas.dirmat, "DNS_" + case_b + ".mat"), 'DNS');
    data_b = DNS.slices;
    end
    if nargin > 3
        load(fullfile(cas.dirmat, "DNS_" + case_c + ".mat"), 'DNS');
        data_c = DNS.slices;
    end
    if nargin > 4
        load(fullfile(cas.dirmat, "DNS_" + case_d + ".mat"), 'DNS');
        data_d = DNS.slices;        
    end
    % Initialize figure and tiled layout
    Ndat = length(data_a.x);
    Ncases = nargin-1;
    fig = figure('Position', [100, 100, 300*Ncases, 800]);
    tiledLayout = tiledlayout(Ndat, Ncases, "TileSpacing", "compact", "Padding", "loose");

    % Preallocate movie vector
    numFrames = 100;
    movieVector(numFrames) = struct('cdata', [], 'colormap', []);

    % Loop through time steps
    for n = 1:numFrames
        ii = 1;
        for loc = 1:Ndat
            % Plot PC-MRI data/results
            create_animation_ansys(data_a, loc, n, ii, Ncases);
            ylabel('Y [cm]', 'Interpreter', 'latex', 'FontSize', 12);
            if loc == Ndat
                xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', 12);
            end
            ii = ii + 1;

            if nargin > 2  
                % Plot data_b data/results
                create_animation_ansys(data_b, loc, n, ii, Ncases);
                ylabel('');
                ii = ii + 1;
                if loc == Ndat
                    xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', 12);
                end
            end
            if nargin > 3
                % Plot data_b data/results
                create_animation_ansys(data_c, loc, n, ii, Ncases);
                ylabel('');
                ii = ii + 1;
                if loc == Ndat
                    xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', 12);
                end
            end
            if nargin > 4
                % Plot data_b data/results
                create_animation_ansys(data_d, loc, n, ii, Ncases);
                ylabel('');
                ii = ii + 1;
                if loc == Ndat
                    xlabel('X [cm]', 'Interpreter', 'latex', 'FontSize', 12);
                end
            end

        end

            prev_ax = gca; % Save the current axis before switching
            load(fullfile(cas.dirmat, "bottom_velocity.mat"),'q');
            
            % Switch to ax1 and plot - to be completed
            ax1 = axes('Position', [0.15 0.12 0.08 0.04]);
            flow_rate(data_a.q{Ndat}, 0)
            ylim([-2,2])
            hold on 
            xline(n/100,LineWidth=1)
            hold off
            set(gca,"FontSize",8)
            ylabel(''); xticks('');
            xlabel(''); yticks('');
            hold off
       
            % Return to the previous axis after plotting in ax1
            axes(prev_ax);  % Restore the previous axis
        

        % Add title to the entire layout
        % title(tiledLayout, sprintf('$t/T = %.2f$', n / numFrames), ...
        %     'Interpreter', 'latex', 'FontSize', 20);

        % Capture the frame
        set(gcf, 'Color', 'w')
        movieVector(n) = getframe(fig);
        drawnow;
    end

    % Save the animation
    if nargin == 5
        outputFileName = fullfile(cas.dirvid, "2D_comparison_" + string(data_b.case) + "_" + string(data_c.case) + "_" + string(data_d.case));
    elseif nargin == 4
        outputFileName = fullfile(cas.dirvid, "2D_comparison_" + string(data_b.case) + "_" + string(data_c.case));
    else
    outputFileName = fullfile(cas.dirvid, "2D_comparison_" + data_b.case);
    end
    save_animation(movieVector, outputFileName);
end

function create_animation_ansys(data, loc, n, ii, Ncases)
    % Extract data and rescale
    x = data.x{loc} * 1e2; % [cm]
    y = data.y{loc} * 1e2; % [cm]
    w = data.u_normal{loc}(:, n) * 1e2; % [cm/s]

    % Create interpolation grid
    xq = linspace(min(x), max(x), 1000);
    yq = linspace(min(y), max(y), 1000);
    [Xq, Yq] = meshgrid(xq, yq);
    Wq = griddata(x, y, w, Xq, Yq, 'cubic');

    % Plot in the specified tile
    nexttile(ii);
    scatter(x, y, 10, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    bluetored(6);

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
    box on;
    if n==1 && mod(ii-1, Ncases) == 0 
        named_location (gca, data.locations{loc})
    end
    if mod(ii, Ncases) ~= 0 
        colorbar off;
    end
    if ii < Ncases + 1
        sstt = data.case;  % Assuming 'data.case' is a string
        if ~strcmp(sstt, 'PC-MRI')  % Use strcmp to compare strings
            sstt = extractBetween(sstt,1,2) + " DNS";  % Concatenate with " DNS"
        end
        title(sstt)
    end
end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
end

function named_location (gca, sstt)
        % Get the position of the current tile (in normalized figure coordinates)
    ax = gca;  % Get the current axis handle
    axPos = ax.Position;  % Position of the axis [left, bottom, width, height]

    % Compute normalized figure coordinates for the top-left corner of the tile
    % Axes position is in normalized figure coordinates [0, 1], so adjust for annotation
    xPos = axPos(1);  % X position of the tile
    yPos = axPos(2) + axPos(4)- 0.02;  % Slightly offset from the top (5% from the top edge of the tile)
    width = 0.2 * axPos(3);  % Width of the textbox (20% of the tile's width)
    height = 0.05 * axPos(4);   % Height of the textbox (5% of figure height)

    % Position it in the top-left corner of the tile using normalized figure coordinates
   dim = [xPos, yPos, width, height];
    
    % Create the textbox
    annotation('textbox', dim, 'String', sstt, 'FontSize', 12, 'Color', 'black', ...
               'EdgeColor', 'none', 'BackgroundColor', 'none', 'Interpreter', 'latex');
end