function dat = apply_ROI_compute_Q(dat, correct_aliasing, smooth_spatial_outliers, gauss_filter)

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

        % === Aliasing correction ===
        if correct_aliasing
            UU = U_SAS{idat};  
            wrapped_phase = (pi / venc{idat}) * UU;

            % temporal unwrap to reduce aliasing
            unwrapped_phase = unwrap_time_periodic(wrapped_phase);
            UU_corr = (venc{idat} / pi) * unwrapped_phase;
            U_SAS{idat} = UU_corr;
            pxpos_alias_idat = abs(UU_corr - UU) > 1.0e-6;
            pxpox_alias{idat} = pxpos_alias_idat;
        else
            pxpox_alias = 0;
        end

        % === Smooth spatial outliers based on local statistics ===
        if smooth_spatial_outliers
            threshold = 0.2 * venc{idat}; 
            [U_SAS{idat}, outlier_masks{idat}] = smooth_spatial_outliers_3D(U_SAS{idat}, threshold);

            
        end

        % === Compute flow rates and mean velocities ===
        for it = 1:Nt{idat}

        % gaussian smoothing in space
        if gauss_filter 
            U_SAS{idat}(:, :, it)=imgaussfilt(U_SAS{idat}(:, :, it), 0.8);
        end

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

    % if smooth_spatial_outliers
    %     dat.outlier_masks = outlier_masks;
    % end

end

function [U_smooth, outlier_mask_all] = smooth_spatial_outliers_3D(U, threshold)
    % Smooth spatial outliers in a 3D velocity matrix (x, y, time)
    % 
    % INPUT:
    %   U         : 3D velocity field [Nx, Ny, Nt] to be filtered
    %   threshold : absolute difference threshold to identify outliers
    %
    % OUTPUT:
    %   U_smooth         : filtered velocity field with outliers replaced
    %   outlier_mask_all : logical 3D mask marking detected outlier locations

    [Nx, Ny, Nt] = size(U);  % Get the spatial and temporal dimensions

    U_smooth = U;  % Initialize the output with the input velocity field
    outlier_mask_all = false(Nx, Ny, Nt);  % Initialize logical mask of outliers

    for t = 1:Nt
        % Extract 2D velocity field at time t
        frame = U(:, :, t);

        % Apply a 3x3 median filter to the frame
        % This computes the median of each 3x3 neighborhood
        frame_median = medfilt2(frame, [3 3]);

        % Identify outliers: pixels whose value deviates from the median
        % by more than the specified threshold
        outlier_mask = abs(frame - frame_median) > threshold;

        % Replace the outliers with the corresponding median-filtered values
        frame(outlier_mask) = frame_median(outlier_mask);

        % Store the corrected frame back into the output
        U_smooth(:, :, t) = frame;

        % Save the outlier mask for this frame
        outlier_mask_all(:, :, t) = outlier_mask;
    end
end

function unwrapped = unwrap_time_periodic(wrapped)
    [Nx, Ny, Nt] = size(wrapped);
    unwrapped = wrapped;

    for i = 1:Nx
        for j = 1:Ny
            unwrapped(i,j,:) = unwrap(squeeze(wrapped(i,j,:)));
        end
    end

    % Enforce periodicity between first and last frames
    dphi = unwrapped(:,:,1) - unwrapped(:,:,end);
    nwrap = round(dphi / (2*pi));

    for t = 1:Nt
        unwrapped(:,:,t) = unwrapped(:,:,t) - 2*pi * nwrap;
    end
end
