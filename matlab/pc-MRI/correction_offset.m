function dat = correction_offset(dat)
% Subtract precomputed constant offsets (dat.U_*_off{idat}) so that each
% region's cycle-averaged flow is zero. Recompute Q_* and mean_U_*.
% No re-computation of offsets — we use the ones already stored in dat.

    Ndat       = dat.Ndat;
    onepxarea  = dat.onepxarea;

    for idat = 1:Ndat
        % --- SAS ---
        [dat.U_SAS{idat}, dat.Q_SAS{idat}, dat.mean_U_SAS{idat}] = ...
            apply_offset(dat.U_SAS{idat}, dat.ROI_SAS{idat}, ...
                                             dat.area_SAS{idat}, onepxarea{idat}, ...
                                             dat.U_SAS_off{idat});

        % --- COR ---
        [dat.U_COR{idat}, dat.Q_COR{idat}, dat.mean_U_COR{idat}] = ...
            apply_offset(dat.U_COR{idat}, dat.ROI_COR{idat}, ...
                                             dat.area_COR{idat}, onepxarea{idat}, ...
                                             dat.U_COR_off{idat});
        % --- SPC ---
        [dat.U_SPC{idat}, dat.Q_SPC{idat}, dat.mean_U_SPC{idat}] = ...
            apply_offset(dat.U_SPC{idat}, dat.ROI_SPC{idat}, ...
                                             dat.area_SPC{idat}, onepxarea{idat}, ...
                                             dat.U_SPC_off{idat});

        % --- TONS ---
        [dat.U_TONS{idat}, dat.Q_TONS{idat}, dat.mean_U_TONS{idat}] = ...
            apply_offset(dat.U_TONS{idat}, dat.ROI_TONS{idat}, ...
                                             dat.area_TONS{idat}, onepxarea{idat}, ...
                                             dat.U_TONS_off{idat});
    end
end

% ---------------- helper (uses known offset u0) ----------------
function [U_corr, Q_new, meanU_new] = apply_offset(U_in, ROI, A, onepxarea, u0)
    % If no area, return passthrough
    if isempty(A) || A<=0
        U_corr   = U_in;
        Nt_i     = size(U_in,3);
        Q_new    = zeros(1, Nt_i);
        meanU_new= NaN(1, Nt_i);
        return
    end

    % Subtract constant velocity offset only within the mask
    mask = ROI; if ~islogical(mask), mask = logical(mask); end
    U_corr = U_in;
    Nt_i = size(U_in,3);
    for it = 1:Nt_i
        U_corr(:,:,it) = U_corr(:,:,it) - u0 * mask;
    end

    % Recompute Q(t) and mean_U(t)
    Q_new     = zeros(1, Nt_i);
    meanU_new = zeros(1, Nt_i);
    for it = 1:Nt_i
        Ui = U_corr(:,:,it) .* mask;
        Q_new(it)     = sum(sum(Ui)) * onepxarea;
        meanU_new(it) = Q_new(it) / A;
    end
end