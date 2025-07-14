%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;
addpath("../processing/Functions/")
addpath('../processing/Functions/Others/')

[cas, dat_PC, t0] = run_if_empty('s101_b');  % Load data if not already
visualization_plots = false;
do_registration = false;
modes = 30; 

python_venv = "/Users/noza/Documents/chiari/git-chiari/venv/bin/python3.11";
slicer_3D_path = "/Applications/Slicer.app/Contents/MacOS/Slicer";

% --- Validate Python and Slicer paths
if ~isfile(python_venv)
    error("Python virtual environment not found at: %s", python_venv);
end

if ~isfile(slicer_3D_path)
    error("Slicer executable not found at: %s", slicer_3D_path);
end

segmentation_script = fullfile(pwd, '..', '..', 'slicer3D-code', 'segmentation-2D.py');
registration_script = full_path(fullfile(pwd, '..', '..', 'slicer3D-code','registration-velocity.py'));
dir_chiari = full_path(fullfile(pwd, '..', '..', '..'));

% === Define and create output directories ===
segmentation_dir         = fullfile(cas.dirdat, cas.subj, "registration", "2D-segmentation");
input_registration_dir   = fullfile(cas.dirdat, cas.subj, "registration", "input-velocity");
output_registration_dir  = fullfile(cas.dirdat, cas.subj, "registration", "output-velocity");

cellfun(@(d) ~exist(d, 'dir') && mkdir(d), ...
    {segmentation_dir, input_registration_dir, output_registration_dir});

% Check if registration output already exists and is newer than input
reg_files = dir(fullfile(output_registration_dir, '*.nrrd'));

% do_registration = check_if_registration_exists(reg_files, t0);

if do_registration
    % === Loop over slices and time steps ===
    for i = 1:length(cas.locations)
        % ROI and coordinate grid
        roi = dat_PC.ROI_SAS{i};
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
        roi_filename = fullfile(segmentation_dir, cas.locations{i} + "_roi.nrrd");
        nrrdwrite(roi_filename, img);
    
        % Save velocity frames
        for n = 1:dat_PC.Nt{i}
            u = dat_PC.U_SAS{i}(:, :, n);
            img.pixelData = double(u);
            u_filename = fullfile(input_registration_dir, cas.locations{i} + "_u_" + n + ".nrrd");
            nrrdwrite(u_filename, img);
        end
    end
    
    disp('.nrrd files created with ROI and velocity information ...')

    % 1. Create 2D segmentations using 3D Slicer
    cmd1 = slicer_3D_path + " --no-main-window --python-script " + segmentation_script + " " + cas.subj + " " + dir_chiari;
    system(cmd1); 
    disp('2D segmentations created using 3D slicer ...  ')
    
    % 2. Run velocity registration using ANTs
    cmd2 = python_venv + " " + registration_script + " " + cas.subj + " " + dir_chiari;
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
    [velocity.ROI_SAS{i}] = read_ROI_nrrd(location, segmentation_dir);

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
    
    plot_flow_rates(velocity, cas);  % <-- add this line

    ts_cycle = 40; 
    movieVector = create_animation(dat_PC, cas, ts_cycle);
    
    save_animation(movieVector, fullfile(cas.dirvid, "flow_measurements_"+cas.subj+".mp4"));
end

dat_PC = update_data(velocity, dat_PC, modes);

dat_PC.dx = dx;
dat_PC.dy = dy;

disp("Saving everything in a .mat file ..." + newline)
save(fullfile(cas.dirmat, "04-registration.mat"), 'cas', 'dat_PC');
disp( "Done!" + newline)



function [cas, dat_PC, file_time] = run_if_empty(subject)

    file_path = fullfile("..", "..", "..", "computations", "pc-mri", subject, "mat", "03-apply_roi_compute_Q.mat");
    load(file_path, 'cas', 'dat_PC');

    file_info = dir(file_path);
    file_time = datetime(file_info.datenum, 'ConvertFrom', 'datenum');
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
                disp("⏩ Skipping registration step.")
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
% Plot ROI masks (top), unregistered (middle), and registered (bottom)
% velocity fields for all locations at a specific time step.

    N = length(cas.locations);  % number of locations

    figure('Units', 'normalized', 'Position', [0.05 0.2 0.95 0.75]);
    tiledlayout(3, N, 'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:N
        location = cas.locations{i};

        % === Unregistered ===
        U2 = dat_PC.U_SAS{i}(:, :, tstep);
        XYZ2 = dat_PC.pixel_coord{i};
        x2 = XYZ2(:,:,1); y2 = XYZ2(:,:,2); z2 = XYZ2(:,:,3);
        x2 = x2(:); y2 = y2(:); z2 = z2(:); u2 = U2(:);

        nexttile(i)
        scatter3(x2, y2, z2, 10, u2, 'filled');
        title(sprintf('%s (Unreg)', location));
        axis equal tight
        view(2)
        colorbar
        set(gca, 'XTick', [], 'YTick', []);

        % === Registered ===
        U1 = velocity.U_SAS{i}(:, :, tstep);
        XYZ1 = velocity.pixel_coord{i};
        x1 = XYZ1(:,:,1); y1 = XYZ1(:,:,2); z1 = XYZ1(:,:,3);
        x1 = x1(:); y1 = y1(:); z1 = z1(:); u1 = U1(:);

        nexttile(N + i)
        scatter3(x1, y1, z1, 10, u1, 'filled');
        title(sprintf('%s (Reg)', location));
        axis equal tight
        view(2)
        colorbar
        set(gca, 'XTick', [], 'YTick', []);

        % === ROI mask ===
        ROI = velocity.ROI_SAS{i};
        [ny, nx] = size(ROI);
        [X, Y] = meshgrid(1:nx, 1:ny);

        nexttile(2*N + i)
        scatter(X(:), Y(:), 10, double(ROI(:)), 'filled');
        title(sprintf('%s (ROI)', location));
        axis equal tight
        view(2)
        colormap(gca, gray)  % apply gray only to this tile
        colorbar
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
        [~, a0, am, fm] = four_approx(dat_PC.Q_SAS{k}, modes, 0, 100);
        velocity.fou.fm{k} = fm;
        velocity.fou.am{k} = am;
        velocity.fou.a0{k} = a0;
    end
end

function roi_mask = read_ROI_nrrd(location, segmentation_dir)
% Read a binary ROI mask from a _segmentation.nrrd file
%
% Inputs:
%   location         - string, e.g., "FM", "UPFM"
%   segmentation_dir - path to directory containing *_segmentation.nrrd files
%
% Output:
%   roi_mask - 2D binary mask (1 inside ROI, 0 outside)

    % Build the file path
    filename = fullfile(segmentation_dir, location + "_segmentation.nrrd");

    if ~isfile(filename)
        error("ROI file not found: %s", filename);
    end

    % Read the image
    roi_raw = nrrdread(filename);

    % Convert to binary mask: keep all nonzero values
    roi_mask = roi_raw > 0;
end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
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





% 
% function dat = fourier_decompose_signal(dat)
% %FOURIER_DECOMPOSE_SIGNAL Decomposes input signals into Fourier series
% %
% % Inputs:
% %   dat   - struct containing fields:
% %             .Ndat      - number of datasets
% %             .T         - cell array of periods
% %             .t_ip      - cell array of time vectors
% %             .Q_SAS_ip  - cell array of signals
% %             .Nt_ip     - number of time steps
% %             .dt_ip     - time step
% %   M     - number of Fourier modes
% %   Nrep  - number of signal repetitions for better frequency resolution
% %
% % Output:
% %   dat.fou.fm - cell array of frequency components
% %   dat.fou.am - cell array of complex amplitudes
% 
%     Ndat = dat.Ndat;
%     T    = dat.T;
%     t    = dat.t;
%     Q    = dat.Q_SAS;
%     N1   = dat.Nt{1};
%     Nrep = 4;
%     M    = 20; %30
% 
%     for idat = 1:Ndat
%         TT  = T{idat};
%         tt  = t{idat};
%         QQ  = Q{idat};
% 
%         tt(end) = []; % Trim last point
%         QQ(end) = [];
% 
%         if length(tt) ~= N1
%             warning("Length mismatch at dataset %d", idat);
%         end
% 
%         % Repeat signal Nrep times
%         ttt = tt;
%         QQQ = QQ;
%         for irep = 1:Nrep-1
%             ttt = [ttt, tt + irep*TT];
%             QQQ = [QQQ, QQ];
%         end
% 
%         % Compute FFT
%         L  = Nrep * N1;
%         Fs = N1 * 2*pi / TT;
%         f  = Fs * (0:(L/2)) / L;
%         Y  = fft(QQQ);
%         P2 = Y / L;
%         P  = P2(1:L/2+1);
%         a0 = P(1);
% 
%         % Extract harmonics
%         fm = zeros(1, M);
%         am = zeros(1, M);
%         for m = 1:M
%             idx = m * Nrep + 1;
%             if idx <= length(f)
%                 fm(m) = f(idx);
%                 am(m) = P(idx);
%             else
%                 warning("Index %d exceeds frequency array size", idx);
%                 break;
%             end
%         end
% 
%         dat.fou.fm{idat} = fm;
%         dat.fou.am{idat} = am;
%         dat.fou.a0{idat} = a0;
%     end
% 
%     dat.fou.M = M;
% 
% end
