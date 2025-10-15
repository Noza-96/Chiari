%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cas,dat_PC] = main_2_crop_set_roi(cas,dat_PC, crop_size)

fprintf('\n4) PC-MRI measurements...\n')

reference_location = 'C3C4'; 
% (set to 'zero' to set location to 0.0)
% (set to 'fromsag' to replace ljocations with those from sagittal geometry)
% (e.g. 'C02C03' to shift all locationsy so that the C02C03 locations coincides with sagittal geometry)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp("Adjusting vertical location ..." + newline)

dat_PC = adjust_vertical_location_PC(cas, dat_PC, reference_location);

disp("Cropping data ..." + newline)

dat_PC = crop_data(cas, dat_PC, crop_size);

disp("Setting up ROIs ..." + newline)

dat_PC = define_ROI_video(cas, dat_PC);

disp("Saving everything in a .mat file ..." + newline)

save(fullfile(cas.dir.mat, "data_2.mat"), 'cas', 'dat_PC');
disp("Done!" + newline)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end