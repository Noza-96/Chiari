function dat = apply_ROI_compute_Q(dat, plot_frame_id)

    correct_aliasing = true;
    smooth_spatial_outliers = true;  % Flag to apply spatial outlier smoothing
    do_plot = nargin > 1;  % Only plot if plot_frame_id is provided

    Ndat = dat.Ndat;
    fcal_H_cm_px = dat.fcal_H_cm_px;
    fcal_V_cm_px = dat.fcal_V_cm_px;
    Nt = dat.Nt;
    venc = dat.venc;

    ROI_SAS = dat.ROI_SAS;
    ROI_COR = dat.ROI_COR;
    ROI_SPC = dat.ROI_SPC;

    U_tot = dat.U_tot;

    for idat = 1:Ndat

        onepxarea{idat} = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

        px_area_SAS{idat} = sum(sum(ROI_SAS{idat}));
        px_area_COR{idat} = sum(sum(ROI_COR{idat}));
        px_area_SPC{idat} = sum(sum(ROI_SPC{idat}));

        area_SAS{idat} = px_area_SAS{idat} * onepxarea{idat};
        area_COR{idat} = px_area_COR{idat} * onepxarea{idat};
        area_SPC{idat} = px_area_SPC{idat} * onepxarea{idat};

        % Initialize region-masked velocity volumes
        for it = 1:Nt{idat}
            U_SAS{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_SAS{idat};
            U_COR{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_COR{idat};
            U_SPC{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_SPC{idat};
        end

        % === Apply aliasing correction in 3D (space + time) ===
        if correct_aliasing
            UU = U_SAS{idat};  % [x, y, t]
            wrapped_phase = (pi / venc{idat}) * UU;
            unwrapped_phase = unwrap(wrapped_phase, [], 3);
            UU_corr = (venc{idat} / pi) * unwrapped_phase;

            U_SAS{idat} = UU_corr;
            pxpos_alias_idat = abs(UU_corr - UU) > 1.0e-6;
            pxpox_alias{idat} = pxpos_alias_idat;
        end

        % === Smooth spatial outliers based on local statistics ===
        if smooth_spatial_outliers
            threshold = 0.2 * venc{idat};  % More intuitive, tune as needed
        
            for it = 1:Nt{idat}
                frame = U_SAS{idat}(:, :, it);
        
                % Median-filtered version of the frame
                frame_median = medfilt2(frame, [3 3]);
        
                % Detect pixels that differ too much from the local median
                outlier_mask = abs(frame - frame_median) > threshold;
        
                % Replace outlier pixels
                frame(outlier_mask) = frame_median(outlier_mask);
        
                % Save corrected frame
                U_SAS{idat}(:, :, it) = frame;
        
                % Optional: store outlier mask
                outlier_masks{idat}(:, :, it) = outlier_mask;
            end
        end

        % === Compute flow rates and mean velocities ===
        for it = 1:Nt{idat}
            Q_SAS{idat}(it) = sum(sum(U_SAS{idat}(:, :, it))) * onepxarea{idat};
            Q_COR{idat}(it) = sum(sum(U_COR{idat}(:, :, it))) * onepxarea{idat};
            Q_SPC{idat}(it) = sum(sum(U_SPC{idat}(:, :, it))) * onepxarea{idat};

            mean_U_SAS{idat}(it) = Q_SAS{idat}(it) / area_SAS{idat};
            mean_U_COR{idat}(it) = Q_COR{idat}(it) / area_COR{idat};
            mean_U_SPC{idat}(it) = Q_SPC{idat}(it) / area_SPC{idat};
        end
    end

    % === Assign outputs ===
    dat.onepxarea = onepxarea;
    dat.pxpos_alias = pxpox_alias;

    dat.px_area_SAS = px_area_SAS;
    dat.px_area_COR = px_area_COR;
    dat.px_area_SPC = px_area_SPC;

    dat.area_SAS = area_SAS;
    dat.area_COR = area_COR;
    dat.area_SPC = area_SPC;

    dat.U_SAS = U_SAS;
    dat.U_COR = U_COR;
    dat.U_SPC = U_SPC;

    dat.Q_SAS = Q_SAS;
    dat.Q_COR = Q_COR;
    dat.Q_SPC = Q_SPC;

    dat.mean_U_SAS = mean_U_SAS;
    dat.mean_U_COR = mean_U_COR;
    dat.mean_U_SPC = mean_U_SPC;

    if smooth_spatial_outliers
        dat.outlier_masks = outlier_masks;
    end

end

