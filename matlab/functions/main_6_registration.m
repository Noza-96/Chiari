%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cas,dat_PC] = main_6_registration(cas)

    % This sets the location in which you want to do registration, as it
    % is, only does registration of most caudal measurement
    loc_registration = cas.locations{end};

    fprintf("6) Registration:\n")    

    data_now = "data_3.mat";

    [cas, dat_PC, didSkip] = check_data_updated(cas, data_now, "data_2.mat", dir(fullfile(cas.dir.trans, '*')));
    dat_0 = dat_PC;
    if didSkip, return, end   

    % idx locations to do registration
    idx = find(contains(string(cas.locations), loc_registration));

    visualization_plots = true;
    
    python_path = fullfile(config_path('python', fullfile(cas.dir.chiari, 'config_file.txt')));
    
    % --- Valie Python path
    if ~isfile(python_path)
        error("Python virtual environment not found at: %s", python_path);
    end
    
    segmentation_script = fullfile(cas.dir.git, 'slicer3D-code', 'segmentation-2D.py');
    registration_script = full_path(fullfile(cas.dir.git, 'slicer3D-code','registration-velocity.py'));
    
    % === Define and create output directories ===
    segmentation_2D         = fullfile(cas.dir.reg, "2D-segmentation");
    input_registration_dir   = fullfile(cas.dir.reg, "input-velocity");
    output_registration_dir  = fullfile(cas.dir.reg, "output-velocity");
    
    cellfun(@(d) ~exist(d, 'dir') && mkdir(d), ...
        {segmentation_2D, input_registration_dir, output_registration_dir});
        
    % === Loop over slices and time steps ===
    for i = idx
        fprintf("\n-Registration location: %s \n", cas.locations{idx})
        % ROI and coordinate grid

        filename = cas.locations{idx} + "_transformation.txt";
        transformation_path = fullfile(cas.dir.trans, filename);

        if exist(transformation_path, 'file')
            % Read the matrix (assumes 4 rows, 4 columns, space-separated)
            transformation_matrix = dlmread(transformation_path);            
            dat_PC.pixel_coord{i} = applyTransformation(dat_PC.pixel_coord{i}, transformation_matrix);
            fprintf('\tLinear transformation applied! \n');
        else
            fprintf('\tThere is no linear transformation to apply... \n');
        end

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
        
        fprintf("\tRegistering images using ANTs... \n\n")

        % 1. Create 2D segmentations using 3D Slicer
        run_slicer_python(cas, segmentation_script, 0)
        % 2. Run velocity registration using ANTs
        cmd2 = python_path + " " + registration_script + " " + cas.subj + " " + full_path(cas.dir.chiari) + " " + loc_registration;
        system(cmd2);   
    end
    
    fprintf("\tRecomputing velocity metrics... \n")
    
    for i = idx
        location = cas.locations{i};
        [dat_PC.SAS.ROI{i}] = read_ROI_nrrd(location, segmentation_2D);
        [dat_PC.SAS.U{i}, dat_PC.pixel_coord{i}] = read_velocity_and_coords(location, dat_PC.Nt{i}, output_registration_dir);
    
        coords = dat_PC.pixel_coord{i} / 10.0;
    
        dat_PC.fcal_H_cm_px{i} = mean(sqrt(sum((coords(2:end,:, :) - coords(1:end-1,:, :)).^2, 3)), 'all');
        dat_PC.fcal_V_cm_px{i} = mean(sqrt(sum((coords(:,2:end,:) - coords(:,1:end-1,:)).^2, 3)), 'all');
        dat_PC.onepxarea{i} = dat_PC.fcal_H_cm_px{i} * dat_PC.fcal_V_cm_px{i};

        dat_PC.SAS.area{i}  = sum(sum(dat_PC.SAS.ROI{i}))   * dat_PC.onepxarea{i};
        dat_PC.SAS.Upeak(i)   = max(abs(dat_PC.SAS.U{i}(:)));
    
        dat_PC.SAS.Q{i}   = compute_flow_rate(dat_PC.SAS.U{i}, dat_PC.onepxarea{i});
        [dat_PC.SAS.Q{i}, dat_PC.SAS.fou.a0{i},  dat_PC.SAS.fou.am{i},  dat_PC.SAS.fou.fm{i}]    = four_approx(dat_PC.SAS.Q{i}, dat_PC.SAS.fou.M, 0,  dat_PC.Nt{i});
        dat_PC.SAS.Vs(i)   = compute_stroke_volume(dat_PC.SAS.Q{i}, dat_PC.T{i});

    end
    
    if visualization_plots
        plot_ROI_comparisons(dat_PC, dat_0, cas);

        movieVector = create_animation_pc(dat_PC);

        file_animation_raw = "pcmri_registration.mp4";
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation_raw));
    end
    
    fprintf("\nSaving %s ...\n\n", data_now)
    save(fullfile(cas.dir.mat, data_now), 'cas', 'dat_PC');

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

function plot_ROI_comparisons(dat_PC, dat_0, cas)

    N = length(cas.locations);  % number of locations

    figure('Units', 'normalized', 'Position', [0.05 0.2 0.5 0.4]);
    tiledlayout(2, N, 'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:N
        % === Unregistered ===
        ROI = dat_0.SAS.ROI{i};
        XYZ2 = dat_0.pixel_coord{i};
        x2 = XYZ2(:,:,1); y2 = XYZ2(:,:,2); z2 = XYZ2(:,:,3);
        x2 = x2(:); y2 = y2(:); z2 = z2(:); roi = ROI(:);

        nexttile(i)
        scatter3(x2, y2, z2, 10, roi, 'filled');
        axis equal tight
        colormap(gca, gray)
        view(2)
        % colorbar
        set(gca, 'XTick', [], 'YTick', []);
        nexttile(N + i)

        % === ROI mask ===
        ROI = dat_PC.SAS.ROI{i};
        [ny, nx] = size(ROI);
        [X, Y] = meshgrid(1:nx, 1:ny);
        scatter(X(:), Y(:), 10, double(ROI(:)), 'filled');
        axis equal tight
        view(2)
        colormap(gca, gray)  % apply gray only to this tile
        % colorbar
        set(gca, 'XTick', [], 'YTick', []);
    end

    sgtitle(sprintf('ROI'), 'FontWeight', 'bold');
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

function transformed_pixel_coordinates = applyTransformation(pixel_coordinates, transformation_matrix)
% Apply a 4x4 transformation matrix to a [rows x cols x 3] pixel coordinate grid
%
% Inputs:
%   pixel_coordinates     - [rows x cols x 3] array of original (x,y,z) positions
%   transformation_matrix - [4 x 4] transformation matrix from 3D slicer
%
% Output:
%   transformed_pixel_coordinates - [rows x cols x 3] array of transformed positions

    % Get dimensions
    [rows, cols, ~] = size(pixel_coordinates);
    N = rows * cols;

    % Flatten pixel coordinates into [N x 3]
    coords = reshape(pixel_coordinates, [N, 3]);

    % Convert to homogeneous coordinates [N x 4]
    coords_hom = [coords, ones(N, 1)];

    % Apply transformation matrix [N x 4]
    transformed_coords_hom = (transformation_matrix * coords_hom')';  % [N x 4]

    % Extract (x, y, z)
    transformed_coords = transformed_coords_hom(:, 1:3);

    % Reshape back to [rows x cols x 3]
    transformed_pixel_coordinates = reshape(transformed_coords, [rows, cols, 3]);
end