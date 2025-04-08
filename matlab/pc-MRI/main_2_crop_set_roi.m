%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(who)
    [aux, cas, dat_PC] = run_if_empty('s101_a', 'SIEMENS');  % if skipping previous steps
end

reference_location = 'C03C04'; 
% (set to 'zero' to set location to 0.0)
% (set to 'fromsag' to replace ljocations with those from sagittal geometry)
% (e.g. 'C02C03' to shift all locations so that the C02C03 locations coincides with sagittal geometry)

crop_size = 64; % Number of pixels to crop 256x256 image in

makemovies = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp([newline + "Adjusting vertical location ..." + newline])

dat_PC = adjust_vertical_location_PC(cas, dat_PC, reference_location);

disp([newline + "Cropping data ..." + newline])

dat_PC = crop_data(cas, dat_PC, crop_size);

disp([newline + "Making movies (if requested) ..." + newline])

if makemovies
    make_movies(cas, dat_PC, 'U_tot');
end

disp([newline + "Setting up ROIs ..." + newline])

%dat_PC = define_ROI_freehand(cas, dat_PC);
dat_PC = define_ROI_video(cas, dat_PC);

disp([newline + "Saving everything in a .mat file ..." + newline])

save([cas.dirmat, "/02-"+sstt_name+"crop_set_roi.mat"], 'aux', 'cas', 'dat_PC');

disp([newline + "Done!" + newline])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [aux, cas, dat_PC] = run_if_empty(subject, model)
        cas.subj = subject;
        cas.model = model; % GE (Utah) or SIEMENS (Granada)
        cas = scan_folders_set_cas(cas);
        load([cas.dirmat, "01-"+sstt_name+"read_dat.mat"], 'aux', 'cas', 'dat_PC');
end