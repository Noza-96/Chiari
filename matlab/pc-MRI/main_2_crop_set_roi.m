function [cas,dat_PC] = main_2_crop_set_roi(cas,dat_PC, crop_size)

fprintf('\n4) PC-MRI measurements...\n')

fprintf("- Apply linear transformation to align DICOMs with segmentation...\n")
dat_PC = apply_linear_transformation(dat_PC, cas);

fprintf("\n- Cropping data... \n")

dat_PC = crop_data(cas, dat_PC, crop_size);

fprintf("\n- Setting up ROIs... ")

dat_PC = define_ROI_video(cas, dat_PC);

filename = "data_1.mat";
fprintf("\n\nSaving %s ...\n\n", filename)

save(fullfile(cas.dir.mat, filename), 'cas', 'dat_PC');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end