%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; 

[aux, cas, dat_PC, single_reading] = run_if_empty('s101_b', 'SIEMENS');  % if skipping previous steps

disp("Applying ROIs and computing Q ..." + newline)


correct_aliasing = true; % wrap in time - aliasing correction
unwrap_periodic = true; % allow for periodic wraping
smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
gauss_filter = true; % apply gauss filter

dat_PC = apply_ROI_compute_Q(dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter);

disp(["Repeating and interpolating Q ..." + newline])

dat_PC = repeat_interpolate_Q(dat_PC);

disp(["Computing SV and zero correction ..." + newline])

dat_PC = compute_SVQ_zc(dat_PC);

disp(["Fourier decomposition ..." + newline])

dat_PC = decompose_fourier(cas, dat_PC);

disp("Saving everything in a .mat file ..." + newline)

if isempty(single_reading) 
    sstt_name = "";
else
    sstt_name = strjoin(cellstr(string(single_reading)), '-');
    if ~endsWith(sstt_name, '-')
    sstt_name = sstt_name + "-";
    end
end

save(fullfile(cas.dirmat, "03-"+sstt_name+"apply_roi_compute_Q.mat"), 'aux', 'cas', 'dat_PC');

disp( "Done!" + newline)

function [aux, cas, dat_PC, single_reading] = run_if_empty(subject, model)
        cas.subj = subject;
        cas.model = model; % GE (Utah) or SIEMENS (Granada)
        single_reading = {};
        cas = scan_folders_set_cas(cas, single_reading);
        load([cas.dirmat, '/02-crop_set_roi.mat'], 'aux', 'cas', 'dat_PC');
end

function save_animation(movieVector, fileName)
    % Save the animation as a video
    writer = VideoWriter(fileName, 'MPEG-4');
    writer.FrameRate = 5;
    open(writer);
    writeVideo(writer, movieVector);
    close(writer);
end
