%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; 

[aux, cas, dat_PC, single_reading] = run_if_empty(['s101_aa'], 'SIEMENS');  % if skipping previous steps

reference_location = 'C3C4'; 
% (set to 'zero' to set location to 0.0)
% (set to 'fromsag' to replace ljocations with those from sagittal geometry)
% (e.g. 'C02C03' to shift all locationsy so that the C02C03 locations coincides with sagittal geometry)

crop_size = 100; % Number of pixels to crop 256x256 image in

makemovies = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp("Adjusting vertical location ..." + newline)

dat_PC = adjust_vertical_location_PC(cas, dat_PC, reference_location);

disp("Cropping data ..." + newline)

dat_PC = crop_data(cas, dat_PC, crop_size, single_reading);

disp("Setting up ROIs ..." + newline)

dat_PC = define_ROI_video(cas, dat_PC);

disp("Saving everything in a .mat file ..." + newline)

if isempty(single_reading) 
    sstt_name = "";
else
    sstt_name = strjoin(cellstr(string(single_reading)), '-');
    if ~endsWith(sstt_name, '-')
    sstt_name = sstt_name + "-";
    end
end

save(fullfile(cas.dirmat, "02-"+sstt_name+"crop_set_roi.mat"), 'aux', 'cas', 'dat_PC');
disp("Done!" + newline)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [aux, cas, dat_PC, single_reading] = run_if_empty(subject, model)
        cas.subj = subject;
        cas.model = model; % GE (Utah) or SIEMENS (Granada)
        single_reading = {};
        cas = scan_folders_set_cas(cas, single_reading);
        load(fullfile(cas.dirmat, "01-read_dat.mat"), 'aux', 'cas', 'dat_PC');
end