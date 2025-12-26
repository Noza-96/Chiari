
function [cas,dat_PC] = main_5_apply_roi_compute_Q(cas, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel, fourier_dec)

    fprintf("5) Filter and create animation:\n")    

    file_animation = "pcmri_filtered.mp4";
    data_now = "data_2.mat";

    [cas, dat_0, didSkip] = check_data_updated(cas, data_now, "data_1.mat");
    if didSkip, dat_PC = dat_0; return, end   

    dat_PC = apply_ROI_compute_Q(dat_0, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel, fourier_dec);

    movieVector = create_animation_pc(dat_PC);
    
    if sum([correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel])>0
         
        fprintf("Saving %s and %s...\n\n", data_now, file_animation)
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation));
        save(fullfile(cas.dir.mat, data_now),'cas', 'dat_PC');
        
        file_animation_raw = "pcmri_raw.mp4";

        % #####  Comment if you dont want to analize raw data  #####
        fprintf("Analyzing raw data...\n\n")
        dat_raw = apply_ROI_compute_Q(dat_0, false, false, false, false, false, false);
        movieVector = create_animation_pc(dat_raw);
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation_raw));
        fprintf("Saving %s...\n\n", file_animation_raw);
        % ###########################################################
    end

    close all;
end


function dat_PC = apply_ROI_compute_Q(dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel, fourier_dec)

    factor_threshold = 0.2; % for outliers
    sigma_gauss = 0.8; % standard deviation gauss filter
    Nt_fou = 100;
    modes = 20; %for fourier decomposition 


    Ndat = dat_PC.Ndat;
    venc = dat_PC.venc;
    ROI_SAS  = dat_PC.SAS.ROI;
    ROI_CORD  = dat_PC.CORD.ROI;

    if isfield(dat_PC,'TONS') && isfield(dat_PC.TONS,'ROI')
        ROI_TONS = dat_PC.TONS.ROI;
    else
        ROI_TONS = cellfun(@(x) false(size(x)), ROI_SAS, 'UniformOutput', false);
    end

    % Preallocate outputs as cell arrays
    area_SAS  = cell(Ndat,1); area_CORD = cell(Ndat,1); area_TONS = cell(Ndat,1);
    U_SAS  = cell(Ndat,1); U_CORD = cell(Ndat,1); U_TONS = cell(Ndat,1); 
    Q_SAS  = cell(Ndat,1); Q_CORD = cell(Ndat,1); Q_TONS = cell(Ndat,1);
    Upeak_SAS  = zeros(Ndat,1); Upeak_CORD = zeros(Ndat,1); Upeak_TONS = zeros(Ndat,1);
    Vs_SAS  = zeros(Ndat,1); Vs_CORD = zeros(Ndat,1); Vs_TONS = zeros(Ndat,1);
    a0_SAS = cell(Ndat,1); am_SAS = cell(Ndat,1); fm_SAS = cell(Ndat,1);
    a0_CORD= cell(Ndat,1); am_CORD= cell(Ndat,1); fm_CORD= cell(Ndat,1);
    a0_TONS= cell(Ndat,1); am_TONS= cell(Ndat,1); fm_TONS= cell(Ndat,1);

    for idat = 1:Ndat

        fprintf("- Applying filters and computing flow metrics: %s\n", dat_PC.locations{idat})

        U_tot = - dat_PC.U_tot{idat};

        % --- physical areas (cm^2) ---
        area_SAS{idat}  = sum(sum(ROI_SAS{idat}))   * dat_PC.onepxarea{idat};
        area_CORD{idat}  = sum(sum(ROI_CORD{idat})) * dat_PC.onepxarea{idat};
        area_TONS{idat} = sum(sum(ROI_TONS{idat}))  * dat_PC.onepxarea{idat};

        % --- region-masked velocity volumes ---
        U_SAS{idat}  = U_tot .* ROI_SAS{idat};
        U_CORD{idat} = U_tot .* ROI_CORD{idat};
        U_TONS{idat} = U_tot .* ROI_TONS{idat};

        % === Aliasing correction ===
        if correct_aliasing
            fprintf('\tCorrecting phase aliasing with temporal unwrapping (periodic = %s)...\n', string(logical(unwrap_periodic)));

            UU = U_SAS{idat};
            wrapped_phase = (pi / venc{idat}) * UU;
            unwrapped_phase = unwrap_time_periodic(wrapped_phase, unwrap_periodic);
            U_SAS{idat} = (venc{idat} / pi) * unwrapped_phase;
        end

        % === Smooth spatial outliers based on local statistics ===
        if smooth_spatial_outliers

            fprintf('\tRemoving spatial outliers with 3×3 median filter (threshold = %.2f × venc)...\n', factor_threshold);

            threshold = factor_threshold * venc{idat}; 
            U_SAS{idat}  = smooth_spatial_outliers_3D(U_SAS{idat}, threshold).*ROI_SAS{idat};
            U_CORD{idat} = smooth_spatial_outliers_3D(U_CORD{idat}, threshold).*ROI_CORD{idat};
            if nnz(dat_PC.TONS.ROI{idat}(:)) > 1
                U_TONS{idat} = smooth_spatial_outliers_3D(U_TONS{idat}, threshold).*ROI_TONS{idat};
            end
        end

        % === Gaussian filter ===
        if gauss_filter

            fprintf("\tGaussian filter (sigma = %.2f) ...\n", sigma_gauss)

            % Helper: apply Gaussian filter only within mask (normalize by filtered mask)
            filter_masked = @(U, M, s) ...
                imgaussfilt(U .* M, s, 'FilterDomain', 'spatial') ./ ...
                max(imgaussfilt(double(M), s, 'FilterDomain', 'spatial'), eps);
        
            % Apply to each ROI (vectorized over time automatically)
            U_SAS{idat}  = filter_masked(U_SAS{idat},  ROI_SAS{idat},  sigma_gauss).*ROI_SAS{idat};
            U_CORD{idat} = filter_masked(U_CORD{idat}, ROI_CORD{idat}, sigma_gauss).*ROI_CORD{idat};
            if nnz(dat_PC.TONS.ROI{idat}(:)) > 1
                U_TONS{idat} = filter_masked(U_TONS{idat}, ROI_TONS{idat}, sigma_gauss).*ROI_TONS{idat};
            end
        end
        
        if fourier_dec 
            % Fourier interpolation for velocity profiles
            fprintf("\tDecompose Fourier (modes = %d, Nt = %d) ...\n", modes, Nt_fou)
            U_SAS{idat}  = interp_fourier_truncated(U_SAS{idat},  ROI_SAS{idat},  modes, Nt_fou);
            U_CORD{idat} = interp_fourier_truncated(U_CORD{idat}, ROI_CORD{idat}, modes, Nt_fou);
            if nnz(dat_PC.TONS.ROI{idat}(:)) > 1
                U_TONS{idat} = interp_fourier_truncated(U_TONS{idat}, ROI_TONS{idat}, modes, Nt_fou);
            else
                U_TONS{idat} = zeros([size(U_TONS{idat}(:,:,1)),Nt_fou]);
            end

            dat_PC.t{idat} = (0:(Nt_fou-1))/Nt_fou;
            dat_PC.Nt{idat} = Nt_fou;
        end

        % === Correction offset ===
        if offset_vel

            fprintf("\tCorrection offset...\n")

            U_SAS{idat}  = apply_offset(U_SAS{idat});
            U_CORD{idat} = apply_offset(U_CORD{idat});
            if nnz(dat_PC.TONS.ROI{idat}(:))
                U_TONS{idat} = apply_offset(U_TONS{idat});
            end
    
        end

        % === Compute flow rates and stroke volume ===

        Q_SAS{idat}   = compute_flow_rate(U_SAS{idat}, dat_PC.onepxarea{idat});
        Q_CORD{idat}  = compute_flow_rate(U_CORD{idat}, dat_PC.onepxarea{idat});
        Q_TONS{idat}  = compute_flow_rate(U_TONS{idat}, dat_PC.onepxarea{idat});

        % fourier approximation
        [Q_SAS{idat}, a0_SAS{idat},  am_SAS{idat},  fm_SAS{idat}]    = four_approx(Q_SAS{idat}, modes, 0,  Nt_fou*fourier_dec + dat_PC.Nt{idat}*(~fourier_dec));
        [Q_CORD{idat}, a0_CORD{idat}, am_CORD{idat}, fm_CORD{idat}]  = four_approx(Q_CORD{idat}, modes, 0, Nt_fou*fourier_dec + dat_PC.Nt{idat}*(~fourier_dec));
        [Q_TONS{idat}, a0_TONS{idat}, am_TONS{idat}, fm_TONS{idat}]  = four_approx(Q_TONS{idat}, modes, 0, Nt_fou*fourier_dec + dat_PC.Nt{idat}*(~fourier_dec));

        Vs_SAS(idat)   = compute_stroke_volume(Q_SAS{idat}, dat_PC.T{idat});
        Vs_CORD(idat)  = compute_stroke_volume(Q_CORD{idat}, dat_PC.T{idat});
        Vs_TONS(idat)  = compute_stroke_volume(Q_TONS{idat}, dat_PC.T{idat});

        Upeak_SAS(idat)   = max(abs(U_SAS{idat}(:)));
        Upeak_CORD(idat)  = max(abs(Q_CORD{idat}(:)))/area_CORD{idat};
        if nnz(dat_PC.TONS.ROI{idat}(:))
            Upeak_TONS(idat)  = max(abs(Q_TONS{idat}(:)))/area_TONS{idat};
        end


        fprintf("\n")
    end

    % === Assign outputs ===
    dat_PC.SAS.area  = area_SAS;    dat_PC.CORD.area = area_CORD;     dat_PC.TONS.area = area_TONS;
    dat_PC.SAS.U     = U_SAS;       dat_PC.CORD.U    = U_CORD;        dat_PC.TONS.U    = U_TONS; 
    dat_PC.SAS.Q     = Q_SAS;       dat_PC.CORD.Q    = Q_CORD;        dat_PC.TONS.Q    = Q_TONS;
    dat_PC.SAS.Vs    = Vs_SAS;      dat_PC.CORD.Vs   = Vs_CORD;       dat_PC.TONS.Vs   = Vs_TONS;  
    dat_PC.SAS.Upeak   = Upeak_SAS; dat_PC.CORD.Upeak   = Upeak_CORD; dat_PC.TONS.Upeak   = Upeak_TONS;
    
    dat_PC.SAS.fou.M  = modes;  dat_PC.SAS.fou.a0 = a0_SAS;  dat_PC.SAS.fou.am = am_SAS;  dat_PC.SAS.fou.fm = fm_SAS;
    dat_PC.CORD.fou.M = modes;  dat_PC.CORD.fou.a0 = a0_CORD; dat_PC.CORD.fou.am = am_CORD; dat_PC.CORD.fou.fm = fm_CORD;
    dat_PC.TONS.fou.M = modes;  dat_PC.TONS.fou.a0 = a0_TONS; dat_PC.TONS.fou.am = am_TONS; dat_PC.TONS.fou.fm = fm_TONS;
end

% ---------- helpers (unchanged) ----------
function U_smooth = smooth_spatial_outliers_3D(U, threshold)
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

% ---------------- helper (uses known offset u0) ----------------
function U = apply_offset(U)
    ROI = any(U ~= 0, 3);
    Apx = nnz(ROI);
    % If no area, return passthrough
    pixel_area = 5; 
    Q = compute_flow_rate(U, pixel_area);
    t = linspace(0,1,length(Q));
    Q_off = simps(t, Q, 2);
    u_off = Q_off/(pixel_area*Apx);
    U = U-u_off.*ROI;
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
function Uo = interp_fourier_truncated(Ui, ROI, M, Nt_fou)
% Ui:     Nx×Ny×Nt0    (input time series per pixel)
% ROI:    Nx×Ny        (logical mask)
% M:      number of harmonics to keep (positive modes)
% Nt_fou: output time samples
% Uo:     Nx×Ny×Nt_fou

    [Nx, Ny, Nt0] = size(Ui);
    Uo = zeros(Nx, Ny, Nt_fou, 'like', Ui);

    idx = find(ROI);
    if isempty(idx), return; end

    % Stack ROI pixels into rows: Np × Nt0
    U2 = reshape(Ui, [], Nt0);
    U2 = U2(idx, :);

    % FFT coefficients (normalized)
    C = fft(U2, [], 2) / Nt0;     % Np × Nt0

    % Cap M to what the data can support
    M = min(M, floor((Nt0-1)/2));

    % DC and positive modes
    c0   = C(:, 1);               % Np × 1   (k=0)
    cpos = C(:, 2:M+1);           % Np × M   (k=1..M)

    % New time grid in [0,1)
    t2 = (0:Nt_fou-1)/Nt_fou;     % 1 × Nt_fou

    % Basis for positive modes (M × Nt_fou)
    E = exp(1i*2*pi*(1:M).' .* t2);

    % Truncated reconstruction: u = c0 + 2*Re( cpos * E )
    Urec = c0 + 2*real(cpos * E); % Np × Nt_fou

    % Scatter back to volume
    tmp = zeros(Nx*Ny, Nt_fou, 'like', Ui);
    tmp(idx, :) = Urec;
    Uo = reshape(tmp, Nx, Ny, Nt_fou);
end
