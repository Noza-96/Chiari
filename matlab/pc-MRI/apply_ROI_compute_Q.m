function dat = apply_ROI_compute_Q(dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter)

    Ndat = dat.Ndat;
    fcal_H_cm_px = dat.fcal_H_cm_px;
    fcal_V_cm_px = dat.fcal_V_cm_px;
    Nt   = dat.Nt;
    venc = dat.venc;

    


    ROI_SAS  = dat.ROI_SAS;
    ROI_COR  = dat.ROI_COR;
    ROI_SPC  = dat.ROI_SPC;
    ROI_TONS = [];
    if isfield(dat,'ROI_TONS')
        ROI_TONS = dat.ROI_TONS;
    else
        % if absent, create empty masks so code runs unchanged
        ROI_TONS = cell(Ndat,1);
        for i = 1:Ndat
            ROI_TONS{i} = false(size(ROI_SAS{i}));
        end
    end

    U_tot = dat.U_tot;

    % Preallocate outputs as cell arrays
    onepxarea   = cell(Ndat,1);
    pxpox_alias = cell(Ndat,1);         % SAS alias map (kept for compatibility)
    pxpos_alias_tons = cell(Ndat,1);    % TONS alias map

    px_area_SAS  = cell(Ndat,1);
    px_area_COR  = cell(Ndat,1);
    px_area_SPC  = cell(Ndat,1);
    px_area_TONS = cell(Ndat,1);

    area_SAS  = cell(Ndat,1);
    area_COR  = cell(Ndat,1);
    area_SPC  = cell(Ndat,1);
    area_TONS = cell(Ndat,1);

    U_SAS  = cell(Ndat,1);
    U_COR  = cell(Ndat,1);
    U_SPC  = cell(Ndat,1);
    U_TONS = cell(Ndat,1);

    U_SAS_off  = cell(Ndat,1);
    U_COR_off  = cell(Ndat,1);
    U_SPC_off  = cell(Ndat,1);
    U_TONS_off = cell(Ndat,1);

    Q_SAS  = cell(Ndat,1);
    Q_COR  = cell(Ndat,1);
    Q_SPC  = cell(Ndat,1);
    Q_TONS = cell(Ndat,1);

    mean_U_SAS  = cell(Ndat,1);
    mean_U_COR  = cell(Ndat,1);
    mean_U_SPC  = cell(Ndat,1);
    mean_U_TONS = cell(Ndat,1);

    

    outlier_masks = cell(Ndat,1);          
    outlier_masks_tons = cell(Ndat,1);     

    for idat = 1:Ndat

        onepxarea{idat} = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

        % --- pixel counts (logical masks assumed) ---
        px_area_SAS{idat}  = sum(sum(ROI_SAS{idat}));
        px_area_COR{idat}  = sum(sum(ROI_COR{idat}));
        px_area_SPC{idat}  = sum(sum(ROI_SPC{idat}));
        px_area_TONS{idat} = sum(sum(ROI_TONS{idat}));

        % --- physical areas (cm^2) ---
        area_SAS{idat}  = px_area_SAS{idat}  * onepxarea{idat};
        area_COR{idat}  = px_area_COR{idat}  * onepxarea{idat};
        area_SPC{idat}  = px_area_SPC{idat}  * onepxarea{idat};
        area_TONS{idat} = px_area_TONS{idat} * onepxarea{idat};

        % --- region-masked velocity volumes ---
        U_SAS{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_COR{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_SPC{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_TONS{idat} = zeros(size(U_tot{idat}), 'like', U_tot{idat});

        for it = 1:Nt{idat}
            Ui = U_tot{idat}(:,:,it);
            U_SAS{idat}(:,:,it)  = Ui .* ROI_SAS{idat};
            U_COR{idat}(:,:,it)  = Ui .* ROI_COR{idat};
            U_SPC{idat}(:,:,it)  = Ui .* ROI_SPC{idat};
            U_TONS{idat}(:,:,it) = Ui .* ROI_TONS{idat};
        end

        % === Aliasing correction ===
        % (Original code corrected only SAS; here we also correct TONS for consistency.)
        if correct_aliasing
            % ---- SAS ----
            UU = U_SAS{idat};
            wrapped_phase = (pi / venc{idat}) * UU;
            unwrapped_phase = unwrap_time_periodic(wrapped_phase, unwrap_periodic);
            UU_corr = (venc{idat} / pi) * unwrapped_phase;
            pxpos_alias_idat = abs(UU_corr - UU) > 1.0e-6;
            U_SAS{idat}  = UU_corr;
            pxpox_alias{idat} = pxpos_alias_idat;

            % ---- TONS ----
            UT = U_TONS{idat};
            wrapped_phase_t = (pi / venc{idat}) * UT;
            unwrapped_phase_t = unwrap_time_periodic(wrapped_phase_t, unwrap_periodic);
            UT_corr = (venc{idat} / pi) * unwrapped_phase_t;
            U_TONS{idat} = UT_corr;
            pxpos_alias_tons{idat} = abs(UT_corr - UT) > 1.0e-6;
        else
            pxpox_alias{idat}       = false(size(U_tot{idat}), 'like', logical(1));
            pxpos_alias_tons{idat}  = false(size(U_tot{idat}), 'like', logical(1));
        end

        % === Smooth spatial outliers based on local statistics ===
        if smooth_spatial_outliers
            threshold = 0.2 * venc{idat}; 

            [U_SAS{idat}, outlier_masks{idat}]       = smooth_spatial_outliers_3D(U_SAS{idat}, threshold);
            [U_TONS{idat}, outlier_masks_tons{idat}] = smooth_spatial_outliers_3D(U_TONS{idat}, threshold);
            % If you also want COR/SPC smoothed, uncomment:
            % [U_COR{idat}, ~] = smooth_spatial_outliers_3D(U_COR{idat}, threshold);
            % [U_SPC{idat}, ~] = smooth_spatial_outliers_3D(U_SPC{idat}, threshold);
        end

        % === Compute flow rates and mean velocities ===
        Q_SAS{idat}  = zeros(1, Nt{idat});
        Q_COR{idat}  = zeros(1, Nt{idat});
        Q_SPC{idat}  = zeros(1, Nt{idat});
        Q_TONS{idat} = zeros(1, Nt{idat});

        mean_U_SAS{idat}  = zeros(1, Nt{idat});
        mean_U_COR{idat}  = zeros(1, Nt{idat});
        mean_U_SPC{idat}  = zeros(1, Nt{idat});
        mean_U_TONS{idat} = zeros(1, Nt{idat});

        for it = 1:Nt{idat}
            % optional gaussian smoothing (space) — applied to SAS and TONS
            if gauss_filter
                U_SAS{idat}(:,:,it)  = imgaussfilt(U_SAS{idat}(:,:,it),  0.8);
                U_TONS{idat}(:,:,it) = imgaussfilt(U_TONS{idat}(:,:,it), 0.8);
                % If desired, also:
                % U_COR{idat}(:,:,it)  = imgaussfilt(U_COR{idat}(:,:,it),  0.8);
                % U_SPC{idat}(:,:,it)  = imgaussfilt(U_SPC{idat}(:,:,it),  0.8);
            end

            Q_SAS{idat}(it)  = sum(sum(U_SAS{idat}(:,:,it)))  * onepxarea{idat};
            Q_COR{idat}(it)  = sum(sum(U_COR{idat}(:,:,it)))  * onepxarea{idat};
            Q_SPC{idat}(it)  = sum(sum(U_SPC{idat}(:,:,it)))  * onepxarea{idat};
            Q_TONS{idat}(it) = sum(sum(U_TONS{idat}(:,:,it))) * onepxarea{idat};

            % means: guard divide-by-zero (empty masks)
            if area_SAS{idat}  > 0, mean_U_SAS{idat}(it)  = Q_SAS{idat}(it)  / area_SAS{idat};  else, mean_U_SAS{idat}(it)  = NaN; end
            if area_COR{idat}  > 0, mean_U_COR{idat}(it)  = Q_COR{idat}(it)  / area_COR{idat};  else, mean_U_COR{idat}(it)  = NaN; end
            if area_SPC{idat}  > 0, mean_U_SPC{idat}(it)  = Q_SPC{idat}(it)  / area_SPC{idat};  else, mean_U_SPC{idat}(it)  = NaN; end
            if area_TONS{idat} > 0, mean_U_TONS{idat}(it) = Q_TONS{idat}(it) / area_TONS{idat}; else, mean_U_TONS{idat}(it) = NaN; end
        end

        t_T = linspace(0,1,Nt{idat});

        U_SAS_off{idat}  = simps(t_T, mean_U_SAS{idat}, 2);
        U_COR_off{idat}  = simps(t_T, mean_U_COR{idat}, 2);
        U_SPC_off{idat}  = simps(t_T, mean_U_SPC{idat}, 2);
        U_TONS_off{idat} = simps(t_T, mean_U_TONS{idat}, 2);

    end

    % === Assign outputs ===
    dat.onepxarea   = onepxarea;

    % keep original alias map name (SAS) and add tonsils
    dat.pxpos_alias       = pxpox_alias;        % SAS alias mask
    dat.pxpos_alias_tons  = pxpos_alias_tons;   % TONS alias mask

    dat.px_area_SAS  = px_area_SAS;
    dat.px_area_COR  = px_area_COR;
    dat.px_area_SPC  = px_area_SPC;
    dat.px_area_TONS = px_area_TONS;

    dat.area_SAS  = area_SAS;
    dat.area_COR  = area_COR;
    dat.area_SPC  = area_SPC;
    dat.area_TONS = area_TONS;

    dat.U_SAS  = U_SAS;
    dat.U_COR  = U_COR;
    dat.U_SPC  = U_SPC;
    dat.U_TONS = U_TONS;

    dat.U_SAS_off  = U_SAS_off;
    dat.U_COR_off  = U_COR_off;
    dat.U_SPC_off  = U_SPC_off;
    dat.U_TONS_off = U_TONS_off;

    dat.Q_SAS  = Q_SAS;
    dat.Q_COR  = Q_COR;
    dat.Q_SPC  = Q_SPC;
    dat.Q_TONS = Q_TONS;

    dat.mean_U_SAS  = mean_U_SAS;
    dat.mean_U_COR  = mean_U_COR;
    dat.mean_U_SPC  = mean_U_SPC;
    dat.mean_U_TONS = mean_U_TONS;
end

% ---------- helpers (unchanged) ----------
function [U_smooth, outlier_mask_all] = smooth_spatial_outliers_3D(U, threshold)
    [Nx, Ny, Nt] = size(U);
    U_smooth = U;
    outlier_mask_all = false(Nx, Ny, Nt);
    for t = 1:Nt
        frame = U(:,:,t);
        frame_median = medfilt2(frame, [3 3]);
        outlier_mask = abs(frame - frame_median) > threshold;
        frame(outlier_mask) = frame_median(outlier_mask);
        U_smooth(:,:,t) = frame;
        outlier_mask_all(:,:,t) = outlier_mask;
    end
end

function unwrapped = unwrap_time_periodic(wrapped, periodic)
    [Nx, Ny, Nt] = size(wrapped);
    unwrapped = wrapped;
    for i = 1:Nx
        for j = 1:Ny
            unwrapped(i,j,:) = unwrap(squeeze(wrapped(i,j,:)));
        end
    end
    if periodic == 1
        dphi = unwrapped(:,:,1) - unwrapped(:,:,end);
        nwrap = round(dphi / (2*pi));
        for t = 1:Nt
            unwrapped(:,:,t) = unwrapped(:,:,t) - 2*pi * nwrap;
        end
    end
end