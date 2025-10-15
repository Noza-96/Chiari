%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [aux, cas, dat_PC] = run_if_empty('s4', 'GE');  % if skipping previous steps

function [cas,dat_PC] = main_3_apply_roi_compute_Q(cas,dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel)

    disp("Applying ROIs and computing Q ..." + newline)
    
    visualization_plots = true;
    
    % offset_vel = false; % correction offset velocity
    % correct_aliasing = false; % wrap in time - aliasing correction
    % unwrap_periodic = false; % allow for periodic wraping
    % smooth_spatial_outliers = false;  % Flag to apply spatial outlier smoothing
    % gauss_filter = false; % apply gauss filter
    
    dat_PC = apply_ROI_compute_Q(dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter);
    
    disp(["Repeating and interpolating Q ..." + newline])
    
    if offset_vel == true 
        dat_PC = correction_offset(dat_PC);
    end
    
    dat_PC = repeat_interpolate_Q(dat_PC);
    
    disp(["Computing SV and zero correction ..." + newline])
    
    dat_PC = compute_SVQ_zc(dat_PC);
    
    disp(["Fourier decomposition ..." + newline])
    
    dat_PC = decompose_fourier(cas, dat_PC);
    
    disp("Saving everything in a .mat file ..." + newline)
    
    
    save(fullfile(cas.dir.mat, "data_3.mat"),'cas', 'dat_PC');
    
    disp( "Done!" + newline)
    
    if visualization_plots
        
        % plot_flow_rates(dat_PC, cas);  
    
        movieVector = create_animation_pc(dat_PC, cas);
        
        if offset_vel == true
            save_animation(movieVector, fullfile(cas.dir.vid, "flow_measurements_"+cas.subj+"_off.mp4"));
        else
            save_animation(movieVector, fullfile(cas.dir.vid, "flow_measurements_"+cas.subj+".mp4"));
        end
    
    end
end