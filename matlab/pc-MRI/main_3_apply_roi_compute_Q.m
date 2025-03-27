%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cas.subj = 's101_b';
% 
% cas.model = 'SIEMENS'; % GE (Utah) or SIEMENS (Granada)
% 
% cas = scan_folders_set_cas(cas);
% 
% load([cas.dirmat, '/02-crop_set_roi.mat'], 'aux', 'cas', 'dat_PC');

%% Above to be deleted

disp([newline + "Applying ROIs and computing Q ..." + newline])

dat_PC = apply_ROI_compute_Q(dat_PC);

disp([newline + "Repeating and interpolating Q ..." + newline])

dat_PC = repeat_interpolate_Q(dat_PC);

disp([newline + "Computing SV and zero correction ..." + newline])

dat_PC = compute_SVQ_zc(dat_PC);

disp([newline + "Fourier decomposition ..." + newline])

dat_PC = decompose_fourier(cas, dat_PC);

disp([newline + "Saving everything in a .mat file ..." + newline])

save([cas.dirmat, '/03-apply_roi_compute_Q.mat'], 'aux', 'cas', 'dat_PC');

disp([newline + "Done!" + newline])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
