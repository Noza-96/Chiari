%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

[pcmri, cas, dat_PC] = run_if_empty('s101_b');  % Load data if not already

python_venv = "/Users/noza/Documents/chiari/git-chiari/venv/bin/python3.11";
slicer_3D_path = "/Applications/Slicer.app/Contents/MacOS/Slicer";

segmentation_script = fullfile(pwd, '..', '..', 'slicer3D-code', 'segmentation-2D.py');
registration_script = full_path(fullfile(pwd, '..', '..', 'slicer3D-code','registration-velocity.py'));
dir_chiari = full_path(fullfile(pwd, '..', '..', '..'));

% === Create output directories ===
segmentation_dir         = fullfile(cas.dirdat, cas.subj, "registration", "2D-segmentation");
input_registration_dir   = fullfile(cas.dirdat, cas.subj, "registration", "input-velocity");
output_registration_dir  = fullfile(cas.dirdat, cas.subj, "registration", "output-velocity");

cellfun(@(d) ~exist(d, 'dir') && mkdir(d), ...
    {segmentation_dir, input_registration_dir, output_registration_dir});

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

% 1. Run slicer to clip segmentations (suppress output)
cmd1 = slicer_3D_path + " --no-main-window --settings-path /tmp/slicer-temp-settings --python-script " + segmentation_script + " " + cas.subj + " " + dir_chiari;
system(cmd1);  % discard output
disp('2D segmentations created using 3D slicer ...')

% 2. Run velocity registration using ANTs (suppress output)
cmd2 = python_venv + " " + registration_script + " " + cas.subj + " " + dir_chiari;
system(cmd2);  % discard output
disp('Registration completed using ANTs ...')


function [pcmri, cas, dat_PC] = run_if_empty(subject)

        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "03-apply_roi_compute_Q.mat"),'cas', 'dat_PC');
        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "pcmri_vel.mat"),'pcmri');
end

