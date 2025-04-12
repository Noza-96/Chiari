%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(who)
    [aux, cas, dat_PC, single_reading] = run_if_empty('s101_a', 'SIEMENS');  % if skipping previous steps
end

disp([newline + "Applying ROIs and computing Q ..." + newline])


correct_aliasing = true;
smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
gauss_filter = true;

dat_PC = apply_ROI_compute_Q(dat_PC, correct_aliasing, smooth_spatial_outliers, gauss_filter);

disp([newline + "Repeating and interpolating Q ..." + newline])

dat_PC = repeat_interpolate_Q(dat_PC);

disp([newline + "Computing SV and zero correction ..." + newline])

dat_PC = compute_SVQ_zc(dat_PC);

disp([newline + "Fourier decomposition ..." + newline])

dat_PC = decompose_fourier(cas, dat_PC);

disp([newline + "Saving everything in a .mat file ..." + newline])

if isempty(single_reading) 
    sstt_name = "";
else
    sstt_name = strjoin(cellstr(string(single_reading)), '-');
    if ~endsWith(sstt_name, '-')
    sstt_name = sstt_name + "-";
    end
end

save(fullfile(cas.dirmat, "03-"+sstt_name+"apply_roi_compute_Q.mat"), 'aux', 'cas', 'dat_PC');

disp([newline + "Done!" + newline])

movieVector = create_animation(dat_PC, cas, 40)

save_animation(movieVector, fullfile(cas.dirvid, sstt_name+"flow_measurements_"+cas.subj+".mp4"));


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
