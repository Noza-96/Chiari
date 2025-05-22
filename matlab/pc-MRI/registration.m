%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; 

[pcmri, cas, dat_PC] = run_if_empty('s101_b');  % if skipping previous steps

% TODO:
% 1. For each slice, create nrrd ROI to obtain 2D segmentations anatomy
% 2. For each ts, apply registration velocity, obtaining nrrd
% 3. Interpret nrrd in matlab to obtain new ROI ans velocity.


dat.xyz = dat_PC.pixel_coord;
dat.ROI = dat_PC.ROI_SAS;
dat.U = dat_PC.U_SAS;
dat.ID = cas.locations;

for i = 1:length(dat.ID)
    % Extract fields
    roi = dat.ROI{i};                     % 2D [rows x cols]
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
    nrrd_filename = fullfile(cas.dirdat, cas.subj, "registration", "2D-segmentation", dat.ID{i}+"_roi.nrrd");
    % Create directory if it doesn't exist
    [nrrd_dir, ~, ~] = fileparts(nrrd_filename);
    if ~exist(nrrd_dir, 'dir')
        mkdir(nrrd_dir);
    end
    nrrdwrite(nrrd_filename, img);    

    for n = 1:dat_PC.Nt{i}
        u = dat_PC.U_SAS{i}(:, :, n); 

        % === Save U ===
        img.pixelData = double(u);
        img.ijkToLpsTransform = transform;
        img.metaData.encoding = 'gzip';
        img.metaData.space = 'left-posterior-superior';
        nrrd_filename = fullfile(cas.dirdat, cas.subj, "registration", "input-velocity", dat.ID{i}+"_u_"+n+".nrrd");
        nrrdwrite(sprintf('%s_u.nrrd', dat.ID{i}), img);
            [nrrd_dir, ~, ~] = fileparts(nrrd_filename);
        if ~exist(nrrd_dir, 'dir')
            mkdir(nrrd_dir);
        end
        nrrdwrite(nrrd_filename, img);    
    end

end

python_script = full_path(fullfile(pwd, '..', '..', 'slicer3D-code','transformed_pcmri.py'));

system ("slicer3D  --python-script """ + python_script + """ """ + subject + """ """ + anatomy_dicom + """ """ + dir_chiari + """");


function [pcmri, cas, dat_PC] = run_if_empty(subject)

        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "03-apply_roi_compute_Q.mat"),'cas', 'dat_PC');
        load(fullfile("..","..","..","computations", "pc-mri", subject,"mat", "pcmri_vel.mat"),'pcmri');
end

