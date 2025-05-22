%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; 

[pcmri, cas, dat_PC] = run_if_empty('s101_b');  % if skipping previous steps

dat.xyz = dat_PC.pixel_coord;
dat.ROI = dat_PC.ROI_SAS;
dat.U = dat_PC.U_SAS;
dat.ID = cas.locations;

ts= 35;

for i = 1:length(dat.ID)
    % Extract fields
    roi = dat.ROI{i};                     % 2D [rows x cols]
    u = dat_PC.U_SAS{i}(:, :, ts);       % 2D [rows x cols]
    xyz = dat.xyz{i};                    % 3D [rows x cols x 3]

    % === Compute transform once ===
    origin = squeeze(xyz(1,1,:));                  
    dy = squeeze(xyz(1,2,:) - xyz(1,1,:));         
    dx = squeeze(xyz(2,1,:) - xyz(1,1,:));         
    dz = cross(dx, dy);                            

    R = [dx, dy, dz];                              
    T = origin - dx - dy;
    transform = [R, T; 0 0 0 1];

    % === Save ROI ===
    img.pixelData = double(roi);
    img.ijkToLpsTransform = transform;
    img.metaData.encoding = 'gzip';
    img.metaData.space = 'left-posterior-superior';
    nrrdwrite(sprintf('%s_roi.nrrd', dat.ID{i}), img);

    % === Save U ===
    img.pixelData = double(u);
    img.ijkToLpsTransform = transform;
    img.metaData.encoding = 'gzip';
    img.metaData.space = 'left-posterior-superior';
    nrrdwrite(sprintf('%s_u.nrrd', dat.ID{i}), img);
end

function [pcmri, cas, dat_PC] = run_if_empty(subject)

        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "03-apply_roi_compute_Q.mat"),'cas', 'dat_PC');
        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "pcmri_vel.mat"),'pcmri');
end

