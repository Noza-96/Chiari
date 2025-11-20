%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cas,dat_PC] = main_4_registration(cas)

    fprintf("5) Filter and create animation:\n")    

    data_now = "data_3.mat";

    [cas, dat_0, didSkip] = check_data_updated(cas, data_now, "data_2.mat");
    if didSkip, dat_PC = dat_0; return, end   

    visualization_plots = true;
    
    python_venv = "/Users/noza/Documents/chiari/git-chiari/venv/bin/python3.11";

    
    % --- Validate Python path
    if ~isfile(python_venv)
        error("Python virtual environment not found at: %s", python_venv);
    end
    
    % segmentation_script = fullfile(pwd, '..', '..', 'slicer3D-code', 'segmentation-2D.py');
    registration_script = full_path(fullfile(cas.dir.git, 'slicer3D-code','registration-velocity.py'));
    
    % === Define and create output directories ===
    segmentation_2D         = fullfile(cas.dir.reg, "2D-segmentation");
    input_registration_dir   = fullfile(cas.dir.reg, "input-velocity");
    output_registration_dir  = fullfile(cas.dir.reg, "output-velocity");
    
    cellfun(@(d) ~exist(d, 'dir') && mkdir(d), ...
        {segmentation_2D, input_registration_dir, output_registration_dir});
    
    % Check if registration output already exists and is newer than input
    reg_files = dir(fullfile(output_registration_dir, '*.nrrd'));
    
    do_registration = check_if_registration_exists(reg_files, t0);
    
    if do_registration
        % === Loop over slices and time steps ===
        for i = 1:length(cas.locations)
            % ROI and coordinate grid
            roi = dat_PC.SAS.ROI{i};
            xyz = dat_PC.pixel_coord{i};
        
            % Compute IJK-to-LPS transform
            origin = squeeze(xyz(1,1,:));
            dy = squeeze(xyz(1,2,:) - xyz(1,1,:));
            dx = squeeze(xyz(2,1,:) - xyz(1,1,:));
            dz = cross(dx, dy);
            R = [dx, dy, dz];
            T = origin - dx - dy;
            transform = [R, T; 0 0 0 1];
        
            % Save ROI
            img.pixelData = double(roi);
            img.ijkToLpsTransform = transform;
            img.metaData.encoding = 'gzip';
            img.metaData.space = 'left-posterior-superior';
            roi_filename = fullfile(segmentation_2D, cas.locations{i} + "_roi.nrrd");
            nrrdwrite(roi_filename, img);
        
            % Save velocity frames
            for n = 1:dat_PC.Nt{i}
                u = dat_PC.SAS.U{i}(:, :, n);
                img.pixelData = double(u);
                u_filename = fullfile(input_registration_dir, cas.locations{i} + "_u_" + n + ".nrrd");
                nrrdwrite(u_filename, img);
            end
        end
        
        disp('.nrrd files created with ROI and velocity information ...')
    
        % 2. Run velocity registration using ANTs
        cmd2 = python_venv + " " + registration_script + " " + cas.subj + " " + full_path(cas.dir);
        system(cmd2);   
        disp('Registration completed using ANTs ... ' + newline)
    end
    
    
    % === Load registered velocity .nrrd files ===
    disp("Loading registered velocity fields from: " + output_registration_dir)
    
    velocity = struct();  % container
    
    velocity.U_SAS = cell(1, length(cas.locations));
    velocity.pixel_coord = cell(1, length(cas.locations));
    velocity.Q_SAS = cell(1, length(cas.locations));
    
    fprintf("Reading velocity & coords from .nrrdd ... ")
    
    
    for i = 1:length(cas.locations)
        location = cas.locations{i};
        Nt = dat_PC.Nt{i};
        [velocity.U_SAS{i}, velocity.pixel_coord{i}] = read_velocity_and_coords(location, Nt, output_registration_dir);
        [velocity.ROI_SAS{i}] = read_ROI_nrrd(location, segmentation_2D);
    
        % compute flow rate
        Qi = zeros(1, Nt);
        mask = velocity.ROI_SAS{i};
        coords = velocity.pixel_coord{i};
    
        dx = mean(sqrt(sum((coords(2:end,:, :) - coords(1:end-1,:, :)).^2, 3)), 'all');
        dy = mean(sqrt(sum((coords(:,2:end,:) - coords(:,1:end-1,:)).^2, 3)), 'all');
        dA = dx * dy;
    
        for n = 1:Nt
            u = velocity.U_SAS{i}(:, :, n);
            u_roi = u(mask);
            Qi(n) = sum(u_roi) * dA * 1e-2;
        end
        velocity.Q_SAS{i} = Qi;
    end
    
    if visualization_plots
        plot_all_velocity_comparisons(30, velocity, dat_PC, cas);
        
        plot_flow_rates(velocity, cas);  
    
        ts_cycle = 40; 
        movieVector = create_animation(dat_PC, cas, ts_cycle);
        
        save_animation(movieVector, fullfile(cas.dirvid, "flow_measurements_"+cas.subj+".mp4"));
    end
    
    dat_PC = update_data(velocity, dat_PC, dat_PC.SAS.fou.M);
    
    dat_PC.dx = dx;
    dat_PC.dy = dy;
    
    fprintf("Saving %s ...\n\n", data_now)
    save(fullfile(cas.dir.mat, data_now), 'cas', 'dat_PC');

end

function do_registration = check_if_registration_exists(reg_files, t0)
    do_registration = true;  % default: run registration

    if ~isempty(reg_files)
        % Get latest file modification time
        reg_times = [reg_files.datenum];
        latest_reg_time = datetime(max(reg_times), 'ConvertFrom', 'datenum');

        % Compare to reference time
        if latest_reg_time > t0
            answer = questdlg("Registration already exists and is updated. Do you want to redo it?", ...
                              'Confirm Re-run', 'Yes', 'No', 'No');
    
            if isempty(answer) || strcmp(answer, 'No')
                disp("Skipping registration step.")
                do_registration = false;
            end
        end
    else
        do_registration = true;  % no files exist → should run
    end
end

function [U, xyz] = read_velocity_and_coords(location, Nt, folder)
    % Load velocity frames and compute physical (x,y,z) coordinates

    first_path = fullfile(folder, sprintf('%s_u_1.nrrd', location));
    info = nrrdinfo(first_path);
    I = nrrdread(first_path);
    [ny, nx, ~] = size(I);

    U = zeros(ny, nx, Nt);

    for n = 1:Nt
        file_path = fullfile(folder, sprintf('%s_u_%d.nrrd', location, n));
        if isfile(file_path)
            U(:, :, n) = nrrdread(file_path);
        else
            warning("Missing: %s", file_path);
        end
    end

    % === Compute coordinates using SpatialMapping (affinetform3d)
    tf = info.SpatialMapping;

    % Create 2D grid of pixel indices (MATLAB uses 1-based indexing)
    [Igrid, Jgrid] = ndgrid(1:ny, 1:nx);
    Kgrid = ones(size(Igrid));  % z = 1 since this is a 2D slice

    % Convert voxel indices (i,j,k) to physical (x,y,z)
    ijk = [Jgrid(:), Igrid(:), Kgrid(:)];  % [x=i, y=j, z=1], NRRD uses (col, row, slice)
    xyz_pts = transformPointsForward(tf, ijk);

    % Reshape to (ny x nx x 3)
    x = reshape(xyz_pts(:,1), ny, nx);
    y = reshape(xyz_pts(:,2), ny, nx);
    z = reshape(xyz_pts(:,3), ny, nx);
    xyz = cat(3, x, y, z);
end

function plot_all_velocity_comparisons(tstep, velocity, dat_PC, cas)

    N = length(cas.locations);  % number of locations

    figure('Units', 'normalized', 'Position', [0.05 0.2 0.5 0.4]);
    tiledlayout(2, N, 'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:N
        location = cas.locations{i};

        % === Unregistered ===
        U2 = dat_PC.U_SAS{i}(:, :, tstep);
        ROI = dat_PC.ROI_SAS{i};
        XYZ2 = dat_PC.pixel_coord{i};
        x2 = XYZ2(:,:,1); y2 = XYZ2(:,:,2); z2 = XYZ2(:,:,3);
        x2 = x2(:); y2 = y2(:); z2 = z2(:); u2 = U2(:); roi = ROI(:);

        nexttile(i)
        scatter3(x2, y2, z2, 10, roi, 'filled');
        % title(sprintf('%s (Unreg)', location));
        axis equal tight
        colormap(gca, gray)
        view(2)
        % colorbar
        set(gca, 'XTick', [], 'YTick', []);
        nexttile(N + i)

        % === ROI mask ===
        ROI = velocity.ROI_SAS{i};
        [ny, nx] = size(ROI);
        [X, Y] = meshgrid(1:nx, 1:ny);

        % nexttile(2*N + i)
        scatter(X(:), Y(:), 10, double(ROI(:)), 'filled');
        % title(sprintf('%s (ROI)', location));
        axis equal tight
        view(2)
        colormap(gca, gray)  % apply gray only to this tile
        % colorbar
        set(gca, 'XTick', [], 'YTick', []);
    end

    sgtitle(sprintf('ROI and Velocity Fields at t = %d', tstep), 'FontWeight', 'bold');
end    

function velocity = update_data(velocity, dat_PC, modes)
    velocity.Ndat = dat_PC.Ndat;
    velocity.locz = dat_PC.locz;
    velocity.Nt   = dat_PC.Nt;
    velocity.T    = dat_PC.T;
    velocity.t    = dat_PC.t;
    velocity.fou.M = modes;
    for k = 1:dat_PC.Ndat
        [~, a0, am, fm] = four_approx(velocity.Q_SAS{k}, modes, 1, 100);
        velocity.fou.fm{k} = fm;
        velocity.fou.am{k} = am;
        velocity.fou.a0{k} = a0;
    end
end

function roi_mask = read_ROI_nrrd(location, segmentation_2D)
% Read a binary ROI mask from a _segmentation.nrrd file
%
% Inputs:
%   location         - string, e.g., "FM", "UPFM"
%   segmentation_2D - path to directory containing *_segmentation.nrrd files
%
% Output:
%   roi_mask - 2D binary mask (1 inside ROI, 0 outside)

    % Build the file path
    filename = fullfile(segmentation_2D, location + "_segmentation.nrrd");

    if ~isfile(filename)
        error("ROI file not found: %s", filename);
    end

    % Read the image
    roi_raw = nrrdread(filename);

    % Convert to binary mask: keep all nonzero values
    roi_mask = roi_raw > 0;
end

function plot_flow_rates(velocity, cas)
    N = length(cas.locations);  % number of slices
    figure('Units', 'normalized', 'Position', [0.1 0.2 0.1 0.6]);
    tiledlayout(ceil(N), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:N
        nexttile
        Q = - velocity.Q_SAS{i};       % flow rate
        t = linspace(0,1,length(Q));           % time vector
        flow_rate(Q)
        ylim([-2,2])
        xlabel('Time [s]')
        ylabel('Flow rate [mm^3/s]')
        title(cas.locations{i}, 'Interpreter', 'none')
        grid on
    end

    sgtitle("Flow Rates over Time", 'FontWeight', 'bold');
end

