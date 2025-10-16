%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [aux, cas, dat_PC] = run_if_empty('s4', 'GE');  % if skipping previous steps

function [cas,dat_PC] = main_3_apply_roi_compute_Q(cas, dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel)

    fprintf("- Applying ROIs and computing Q...\n")
    
    
    dat_PC = apply_ROI_compute_Q(dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter);
    
    fprintf("\tCorrection offset ...\n")
    
    if offset_vel == true 
        dat_PC = correction_offset(dat_PC);
    end
    
    dat_PC = repeat_interpolate_Q(dat_PC);
    
    fprintf("\tComputing SV and zero correction ...\n")
    
    dat_PC = compute_SVQ_zc(dat_PC);
    
    fprintf("\tFourier decomposition ...\n")
    
    dat_PC = decompose_fourier(cas, dat_PC);

    movieVector = create_animation_pc(dat_PC, cas);
    
    if sum(correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel)>0
        filename = "data_3.mat"; file_animation = "pcmri_filtered.mp4";
        fprintf("\n\nSaving %s and %s...\n\n", filename, file_animation)
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation));
        save(fullfile(cas.dir.mat, filename),'cas', 'dat_PC');
        
        file_animation_raw = fullfile(cas.dir.vid, "pcmri_raw.mp4");
        if ~exist(file_animation_raw, "file")
            fprintf("\tAnalyze raw data ...")
            dat_raw = apply_ROI_compute_Q(dat, false, false, false, false);
            dat_raw = repeat_interpolate_Q(dat_raw);
            dat_raw = compute_SVQ_zc(dat_raw);
            dat_raw = decompose_fourier(cas, dat_raw);    
            movieVector = create_animation_pc(dat_raw, cas);
            save_animation(movieVector, fullfile(cas.dir.vid, file_animation_raw));
            fprintf("\n\nSaving %s ...\n\n", file_animation_raw);
        end

    
    



    
end