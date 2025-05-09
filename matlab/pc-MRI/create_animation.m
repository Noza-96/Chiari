% Create figure with segmentation together with MRI locations
function movieVector = create_animation(dat_PC, cas, ts_cycle)

addpath("../processing/Functions/")
addpath('../processing/Functions/Others/')

load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');

    
    fs = 12;
    fan = 8;
    locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
    % z-position compared to C3C4
    locz_vals = cell2mat(dat_PC.locz);
    Dz_loc = round(abs(locz_vals(end) - locz_vals)*10);
    % labels = cellfun(@(loc, dz) sprintf('%s (%d mm)', loc, dz), locations, num2cell(Dz_loc), 'UniformOutput', false)

    % Preallocate movie vector
    Ndata = dat_PC.Ndat;
    movieVector(ts_cycle) = struct('cdata', [], 'colormap', []);

    for ii = 1:dat_PC.Ndat

        % pcMRI velocity    
        U = -dat_PC.U_SAS{ii}*1e-2; % m/s
        xyz = dat_PC.pixel_coord{ii}*1e-3; %m
        Q = -dat_PC.Q_SAS{ii};  % Get flow data
    
        % Identify rows and columns where all elements are zero
        % zeroRows = all(U(:,:,1) == 0, 2); % Logical vector for rows
        % zeroCols = all(U(:,:,1) == 0, 1); % Logical vector for columns
        
        % Find the indices of the rows and columns to retain
        % rowsToKeep = find(~zeroRows); 
        % colsToKeep = find(~zeroCols);
        % band = 1; 
	    % rowsToKeep = (rowsToKeep(1)-band):1:(rowsToKeep(end)+band);
	    % colsToKeep = (colsToKeep(1)-band):1:(colsToKeep(end)+band);
        % 
        % Extract the submatrix and update vectors
        % U = U(rowsToKeep, colsToKeep,:);
        % xyz = xyz(rowsToKeep, colsToKeep,:);
        % 
        U = reshape(U,[size(U,1)*size(U,2),size(U,3)]);
    
        %xyz coordinates
        xx = reshape(xyz(:,:,1),[],1);
        yy = reshape(xyz(:,:,2),[],1);
        zz = reshape(xyz(:,:,3),[],1);
        uu = zeros(size(U,1),ts_cycle);
        % We use the fourier approximation to go from 40 data points to 100
        for k=1:size(U,1)
            [uu(k,:), ~, ~] = four_approx(U(k,:), 20, 0, ts_cycle);
        end
    
        x{ii} = xx; y{ii} = yy; z{ii} = zz;
        u{ii} = uu;

        [q{ii}, ~, ~] = four_approx(Q, 20, 0, ts_cycle); 

    end
% Create the structure
pcmri.x = x;
pcmri.y = y;
pcmri.z = z;
pcmri.u_normal = u;
pcmri.q = q;


    rows = 8;
    % Set up figure properties
    figure;
    set(gcf, 'Position', [200, 200, 600, Ndata*150]);
    tt = tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");
    

    % Initialize variables
    Vs = zeros(1, length(dat_PC.Q_SAS));

    for n = 1:ts_cycle
    
        % Loop through each flow data set
        for k = 1:Ndata
            nexttile(1+(k-1)*rows, [1, 3]);
          
            create_animation_ansys(pcmri,length(dat_PC.U_SAS{ii}(:,1,1)), k, n, fan);
            ylabel('$y \,[{\rm mm}]$', 'Interpreter', 'latex', 'FontSize', fs);
            if k == Ndata
                xlabel('$x \,[{\rm mm}]$', 'Interpreter', 'latex', 'FontSize', fs);
            end

            Q = pcmri.q{k};  % Get flow data
            Nt = dat_PC.Nt{k};     % Get number of time points
            t = linspace(0, 1, ts_cycle);  % Create time vector
            if k == 1
                title("$u\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            % Create a new tile for the flow rate
            nexttile(4+(k-1)*rows, [1, 3]);
            Vs(k) = 0.5 * simps(t, abs(Q), 2);  % Compute the volume
    
            % Call the flow rate function
            flow_rate(Q, n);
            set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
            % Set x-tick labels conditionally
            if k < length(dat_PC.Q_SAS)
                xlabel([])
            else
                xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
            end
            xticks(0:0.5:1);

            if k == 1
                title("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            % Set y-labels
            ylim([-2, 2]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            % title(locations{k}, 'Interpreter', 'latex', 'FontSize', fs);

                    % Add title to the entire layout

        end


        if n == 1
            % Plot volumes in the last tile
            nexttile(7,[Ndata, 2]);
            plot(Vs, Dz_loc, '-', 'LineWidth', 1.5);
            hold on
            plot(Vs, Dz_loc, 'o', 'LineWidth', 1.5, 'MarkerFaceColor', 'w');

            yticks(-20:5:100);

            for i = 1:length(anatomy.Dz) - 2
                yline(anatomy.Dz(i), '--', anatomy.location{i}, ...
                    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontSize', fs);
            end             

            ylim([0, ceil(max(Dz_loc(:))/10)*10])
        
            % Customize the appearance of the plot
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
            xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
            ylabel("$z \,{\rm [mm]}$", 'Interpreter', 'latex', 'FontSize', fs);
            xlim([floor(min(Vs(:)) * 10) / 10, ceil(max(Vs(:)) * 10) / 10]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            set(gcf, 'Color', 'w');  % Set background color to white for figures
            grid off;
        end
        % title(tt, sprintf('$t/T = %.2f$', n / ts_cycle), ...
        %         'Interpreter', 'latex', 'FontSize', fs);
        set(gcf, 'Color', 'w')
        movieVector(n) = getframe(gcf);
        drawnow;
    end

    % Set x-ticks for all flow rate tiles


end

function create_animation_ansys(data, N_pixels, loc, n, fan)
    % Extract data and rescale
    x = data.x{loc} * 1e3; % [mm]
    y = data.y{loc} * 1e3; % [mm]
    w = data.u_normal{loc}(:, n) * 1e2; % [cm/s]

    N_pixels

    % Create interpolation grid
    % xq = linspace(min(x), max(x), 1000);
    % yq = linspace(min(y), max(y), 1000);
    % [Xq, Yq] = meshgrid(xq, yq);
    % Wq = griddata(x, y, w, Xq, Yq, 'cubic');

    rows = length(w)/N_pixels;
    x = repmat(1:N_pixels, 1, rows);
    y = repelem(1:N_pixels, rows);

    % Plot in the specified tile
    scatter(x, y, 8, w, 'filled', 'd');
    % contourf(Xq, Yq, Wq, 40, 'LineColor', 'none');
    colorbar;
    bluetored(6);

    % Set axis limits and properties
    Dx = max(x) - min(x);
    Dy = max(y) - min(y);
    % xlim([min(x) - 0.1 * Dx, max(x) + 0.1 * Dx]);
    % ylim([min(y) - 0.1 * Dy, max(y) + 0.1 * Dy]);
    set(gca, 'XDir', 'reverse', 'YDir', 'reverse', 'LineWidth', 1, 'TickLength', [0.01, 0.01], 'FontSize', fan);
    box on;
end