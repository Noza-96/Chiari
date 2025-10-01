close all; clear; clc;
redo_reading = false;

cas.subj = 's4';

cas.model = 'GE'; % GE (Utah) or SIEMENS (Granada)

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

%%  
main_2_crop_set_roi;


%% no-filtering 
correct_aliasing = false; % wrap in time - aliasing correction
unwrap_periodic = false; % allow for periodic wraping
smooth_spatial_outliers = false;  % Flag to apply spatial outlier smoothing
gauss_filter = false; % apply gauss filter
offset_vel = true;

main_3_apply_roi_compute_Q;

dat_PC.U_TONS_off
dat_PC.U_SAS_off
dat_PC.U_COR_off

%% 

% correct_aliasing = true; % wrap in time - aliasing correction
% unwrap_periodic = true; % allow for periodic wraping
% smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
% gauss_filter = true; % apply gauss filter
% 
% main_3_apply_roi_compute_Q;
