% Add functions
clear; close all; clc;
addpath('pc-MRI/');
addpath('processing/');
addpath('processing/Functions/');
addpath('processing/Functions/Others/');

subject = "s4";

%% 1) Organize DICOM data
% out: list DICOMs and organize into flow and anatomy 
cas = organize_DICOMS(subject);

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
run_segmentation(cas)

%% 3) Alignment velocity measurements to segmentation
% out: translation velocity DICOMs to adjucts to segmentation
alignment_MRI(cas)
%% 4) PC-MRI measurements
% out: flow and tissue metrics extracted from PC-MRI measurements

redo_reading = true;
cas.subj = subject; cas.model = 'GE'; % GE (Utah) or SIEMENS (Granada)
cas = scan_folders_set_cas(cas);

if exist(fullfile(cas.dirmat, "01-read_dat.mat")) && ~redo_reading
    load(fullfile(cas.dirmat, "01-read_dat.mat"), 'cas','dat_PC', 'aux');
    fprintf('loading PC-MRI data for:\n')
    for k=1:length(cas.names)
        fprintf('    %s\n', cas.names{k})
    end   
else
    main_1_read_dat;
end

% Define ROI
main_2_crop_set_roi;

% flow metrics
correct_aliasing = true; % wrap in time - aliasing correction
unwrap_periodic = true; % allow for periodic wraping
smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
gauss_filter = true; % apply gauss filter
offset_vel = true;

main_3_apply_roi_compute_Q;


%% 6) Define geometry in SpaceClaim
% out: computational domain

%% 6) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations

%% 5) ANSYS simulations
% out: 

%% 6) Post-processing
% out: computational domain