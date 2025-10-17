%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [aux, cas, dat_PC] = run_if_empty('s4', 'GE');  % if skipping previous steps

function [cas,dat_PC] = main_3_apply_roi_compute_Q(cas, dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel)

    fprintf("5) Filter and create animation:\n")

    file_animation = "pcmri_filtered.mp4";
    data_name = "data_2.mat";

    d_prev = dir(fullfile(cas.dir.mat,"data_1.mat"));
    d_now = dir(fullfile(cas.dir.mat,data_name));

    if exist(fullfile(cas.dir.mat,data_name), 'file')
        if datetime(d_prev.datenum, 'ConvertFrom', 'datenum') > datetime(d_now.datenum, 'ConvertFrom', 'datenum')
            fprintf("- Data needs to be updated...\n")
        else
            if askYN('- Data up to date. Skip? ([y]/n): ')
                load(fullfile(cas.dir.mat, data_name'), 'cas', 'dat_PC');
                return;
            end
        end
    end

    fprintf("- Applying ROIs and computing Q...\n")
    
    
    dat_PC = apply_ROI_compute_Q(dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter);
    
    fprintf("\tCorrection offset...\n")
    
    if offset_vel == true 
        dat_PC = correction_offset(dat_PC);
    end
    
    dat_PC = repeat_interpolate_Q(dat_PC);
    
    fprintf("\tComputing SV and zero correction...\n")
    
    dat_PC = compute_SVQ_zc(dat_PC);
    
    fprintf("\tFourier decomposition...\n")
    
    dat_PC = decompose_fourier(cas, dat_PC);

    movieVector = create_animation_pc(dat_PC, cas);
    
    if sum([correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter, offset_vel])>0
         
        fprintf("Saving %s and %s...\n\n", data_name, file_animation)
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation));
        save(fullfile(cas.dir.mat, data_name),'cas', 'dat_PC');
        
        file_animation_raw = "pcmri_raw.mp4";

        % #####  Comment if you dont want to analize raw data  #####
        fprintf("\tAnalyze raw data...\n")
        dat_raw = apply_ROI_compute_Q(dat, false, false, false, false);
        dat_raw = repeat_interpolate_Q(dat_raw);
        dat_raw = compute_SVQ_zc(dat_raw);
        dat_raw = decompose_fourier(cas, dat_raw);    
        movieVector = create_animation_pc(dat_raw, cas);
        save_animation(movieVector, fullfile(cas.dir.vid, file_animation_raw));
        fprintf("Saving %s...\n\n", file_animation_raw);
        % ###########################################################
    end
end

% Create figure with segmentation together with MRI locations
function movieVector = create_animation_pc(dat_PC, cas)

    % load(fullfile(cas.dirmat,"anatomical_locations.mat"), 'anatomy');

    fs = 20;
    fan = 14;
    locations = cellfun(@(x) strrep(x, '0', ''), cas.locations, 'UniformOutput', false);
    % z-position compared to C3C4
    locz_vals = cell2mat(dat_PC.locz);
    Dz_loc = (locz_vals(1)-locz_vals)*10;

    % Preallocate movie vector
    Ndata = dat_PC.Ndat;
    movieVector(dat_PC.Nt{1}) = struct('cdata', [], 'colormap', []);

    monitors = get(0, 'MonitorPositions');
    monitor1 = monitors(1, :);

    rows = 8;
    % Set up figure properties
    figure;

    % Keep width/height ratio from the original
    aspectRatio = 1000 / (Ndata*240); 
    
    % New desired height = 4/5 of monitor height
    newHeight = 0.8 * monitor1(4);
    
    % Corresponding width to preserve aspect ratio
    newWidth = aspectRatio * newHeight;
    
    % Center horizontally, keep a small top margin
    left = monitor1(1) + (monitor1(3) - newWidth) / 2;
    bottom = monitor1(2) + (monitor1(4) - newHeight) / 2;  % vertically centered
    % or instead of center, you can anchor top/bottom as you like
    
    % Apply new position
    set(gcf, 'Position', [left, bottom, newWidth, newHeight]);

    tiledlayout(Ndata, rows, "TileSpacing", "tight", "Padding", "tight");

    % Initialize variables
    Vs_SAS = zeros(1, length(dat_PC.Q_SAS));
    Vs_TONS = zeros(1, length(dat_PC.Q_TONS));
    Vs_CORD = zeros(1, length(dat_PC.Q_CORD));

    for n = 1:dat_PC.Nt{1}
    
        % Loop through each flow data set
        for k = 1:Ndata
            nexttile(1+(k-1)*rows, [1, 3]);
          
            create_animation_ansys(dat_PC, k, n);

            Q_SAS = -dat_PC.Q_SAS{k};  % Get flow data
            Q_TONS = -dat_PC.Q_TONS{k};  % Get flow data
            Q_CORD = -dat_PC.Q_CORD{k};  % Get flow data

            Nt = dat_PC.Nt{k};     % Get number of time points
            t = linspace(0, 1, dat_PC.Nt{k})*dat_PC.T{k};  % Create time vector
            t_T = linspace(0, 1, dat_PC.Nt{k});
            if k == 1
                title("$u\left[{\rm cm/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            % Create a new tile for the flow rate
            nexttile(4+(k-1)*rows, [1, 3]);
            Vs_SAS(k) = 0.5 * simps(t, abs(Q_SAS), 2);  
            Vs_TONS(k) = 0.5 * simps(t, abs(Q_TONS), 2); 
            Vs_CORD(k) = 0.5 * simps(t, abs(Q_CORD), 2); 

            % Call the flow rate function
            plot(t_T, Q_SAS, Color='k', LineWidth=1.5)
            yline(simps(t_T, Q_SAS, 2), '--','Color', 'k', 'LineWidth', 1, 'HandleVisibility','off');            
            hold on 
            plot(t_T, Q_CORD, Color='b', LineWidth=1.5)
            yline(simps(t_T, Q_CORD, 2), '--','Color', 'b', 'LineWidth', 1, 'HandleVisibility','off');  
            if ~all(Q_TONS == 0)
                plot(t_T, Q_TONS, Color='r', LineWidth=1.5)
                yline(simps(t_T, Q_TONS, 2),'--', 'Color', 'r', 'LineWidth', 1, 'HandleVisibility','off')
            end
            if k == 1
                legend("$Q_{\rm CSF}$", "$Q_{\rm cord}$", "$Q_{\rm tons}$", 'interpreter', 'latex','fontsize',14)
            end
            yline(0,':', 'LineWidth', 1,'HandleVisibility','off')
            xline (t_T(n), '-', 'LineWidth', 1, 'HandleVisibility','off')
            hold off
            set(gca, 'LineWidth', 1, 'TickLength', [0.01 0.01], 'FontSize', fan);
            % Set x-tick labels conditionally
            if k < length(dat_PC.Q_SAS)
                xlabel([])
            else
                xlabel("$t/T$", 'Interpreter', 'latex', 'FontSize', fs);
            end
            xticks(0:0.5:1);

            if k == 1
                title("$Q\left[{\rm ml/s}\right]$", 'Interpreter', 'latex', 'FontSize', fs);
            end
    
            ymin = floor(min([Q_SAS(:); Q_TONS(:)]));
            ymax = ceil(max([Q_SAS(:); Q_TONS(:)]));
        
            % Set y-labels
            ylim([ymin, ymax]);
            ax = gca; % Get current axes
        end


        if n == 1
            % Plot volumes in the last tile
            nexttile(7,[Ndata, 2]);
            plot(Vs_SAS, Dz_loc, '-k', 'LineWidth', 1.5);
            hold on
            plot(Vs_SAS, Dz_loc, 'ok', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            plot(Vs_CORD, Dz_loc, '-b', 'LineWidth', 1.5);
            plot(Vs_CORD, Dz_loc, 'ob', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');


            if ~all(Vs_TONS == 0)
                plot(Vs_TONS, Dz_loc, '-r', 'LineWidth', 1.5);
                plot(Vs_TONS, Dz_loc, 'or', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'HandleVisibility','off');
            end
            legend("$V_{s, \rm CSF}$", "$V_{s, \rm cord}$", "$V_{s, \rm tons}$", 'interpreter', 'latex', 'Location','northwest', 'fontsize',14)

            yticks(-200:5:100);
        
            % Customize the appearance of the plot
            set(gca, 'LineWidth', 1, 'TickLength', [0.005 0.005], 'FontSize', fan);
            xlabel("$V_s \,{\rm [ml]}$", 'Interpreter', 'latex', 'FontSize', fs);
            ylabel("$z \,{\rm [mm]}$", 'Interpreter', 'latex', 'FontSize', fs);
            % xlim([floor(min(Vs_SAS(:)) * 10) / 10, ceil(max(Vs_SAS(:)) * 10) / 10]);'\
            % xlim([0,0.7]);
            ax = gca; % Get current axes
            % ax.XAxis.TickLabelRotation = 90; % Rotate y-axis tick labels to vertical
            set(gcf, 'Color', 'w');  % Set background color to white for figures
            grid off;
        end
        % title(tt, sprintf('$t/T = %.2f$', n / dat_PC.Nt{ii}), ...
        %         'Interpreter', 'latex', 'FontSize', fs);
        set(gcf, 'Color', 'w')
        movieVector(n) = getframe(gcf);
        drawnow;
    end

    % Set x-ticks for all flow rate tiles


end

function create_animation_ansys(dat_PC, loc, n)
    orange = [1, 0.5, 0];
    w_SAS  = -dat_PC.U_SAS{loc}(:,:,n);   % [cm/s]
    w_TONS = -dat_PC.U_TONS{loc}(:,:,n);  % [cm/s]
    w_CORD = -dat_PC.U_CORD{loc}(:,:,n);  % [cm/s]
    
    pcolor(w_SAS + w_TONS + w_CORD);
    shading flat
    axis equal tight ij
    hold on
    box on
    colorbar;
    bluetored(dat_PC.venc{loc});
    xticklabels([]); yticklabels([]);
    
    % outlines
    contour(dat_PC.ROI_SAS{loc},  [0.5 0.5], 'k',      'LineWidth', 1.5);
    contour(dat_PC.ROI_CORD{loc}, [0.5 0.5], 'Color', 'b', 'LineWidth', 1.5);
    if sum(dat_PC.ROI_TONS{loc}(:)) > 0
        contour(dat_PC.ROI_TONS{loc}, [0.5 0.5], 'Color', orange, 'LineWidth', 1.5);
    end


    % filled CORD region (semi-transparent red)
    % cor_mask  = dat_PC.ROI_CORD{loc};
    % alphaFill = 0.35;
    % cor_color = [0.9 0.85 0.7];
    % B = bwboundaries(cor_mask,'noholes');
    % for k = 1:numel(B)
    %     b = B{k};  % [row, col]
    %     patch('XData', b(:,2), 'YData', b(:,1), ...
    %           'FaceColor', cor_color, 'FaceAlpha', alphaFill, ...
    %           'EdgeColor', 'k', 'HitTest','off','PickableParts','none');
    % end
    
    xlim([0.5 size(w_SAS,2)+0.5])
    ylim([0.5 size(w_SAS,1)+0.5])
    hold off
end

function dat = repeat_interpolate_Q(dat)

    Ndat = dat.Ndat;
    
    t  = dat.t;
    T  = dat.T;
    Nt = dat.Nt;
    
    Q_SAS = dat.Q_SAS;
    Q_CORD = dat.Q_CORD;
    Q_DURA = dat.Q_DURA;

    Nrep  = 3;
    Nt_ip = 1024;
    
    for idat = 1:Ndat
        
        % Repeat the signal 3 times (including a last point equal to the first):
        
        t_rep{idat} = t{idat};
        for irep = 1:Nrep-1
            t_rep{idat} = [t_rep{idat}, t{idat} + irep*T{idat}];
        end
        t_rep{idat} = [t_rep{idat}, Nrep*T{idat}];

        Q_SAS_rep{idat} = [repmat(Q_SAS{idat}, [1, Nrep]), Q_SAS{idat}(1)];
        Q_CORD_rep{idat} = [repmat(Q_CORD{idat}, [1, Nrep]), Q_SAS{idat}(1)];
        Q_DURA_rep{idat} = [repmat(Q_DURA{idat}, [1, Nrep]), Q_SAS{idat}(1)];

        % Then interpolate on dense grid:
        
        t_repip{idat} = linspace(t_rep{idat}(1), t_rep{idat}(end), Nrep*Nt_ip + 1);
        
        Q_SAS_repip{idat} = interp1(t_rep{idat}, Q_SAS_rep{idat}, t_repip{idat}, 'makima');
        Q_CORD_repip{idat} = interp1(t_rep{idat}, Q_CORD_rep{idat}, t_repip{idat}, 'makima');
        Q_DURA_repip{idat} = interp1(t_rep{idat}, Q_DURA_rep{idat}, t_repip{idat}, 'makima');
        
        % Then take the complete, interpolated, second cycle:

        ind = t_repip{idat} > T{idat}-1.0e-6 & t_repip{idat} < 2.0*T{idat}+1.0e-6;
        
        t_ip{idat} = t_repip{idat}(ind) - T{idat};

        dt_ip{idat} = t_ip{idat}(2) - t_ip{idat}(1);
        
        Q_SAS_ip{idat} = Q_SAS_repip{idat}(ind);
        Q_CORD_ip{idat} = Q_CORD_repip{idat}(ind);
        Q_DURA_ip{idat} = Q_DURA_repip{idat}(ind);
        
    end
    
    dat.t_rep   = t_rep;

    dat.Q_SAS_rep = Q_SAS_rep;
    dat.Q_CORD_rep = Q_CORD_rep;
    dat.Q_DURA_rep = Q_DURA_rep;

    dat.t_repip = t_repip;

    dat.Q_SAS_repip = Q_SAS_repip;
    dat.Q_CORD_repip = Q_CORD_repip;
    dat.Q_DURA_repip = Q_DURA_repip;

    dat.t_ip  = t_ip;
    dat.Nt_ip = Nt_ip;
    dat.dt_ip = dt_ip;

    dat.Q_SAS_ip = Q_SAS_ip;
    dat.Q_CORD_ip = Q_CORD_ip;
    dat.Q_DURA_ip = Q_DURA_ip;

end

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

        % --- CORD ---
        [dat.U_CORD{idat}, dat.Q_CORD{idat}, dat.mean_U_CORD{idat}] = ...
            apply_offset(dat.U_CORD{idat}, dat.ROI_CORD{idat}, ...
                                             dat.area_CORD{idat}, onepxarea{idat}, ...
                                             dat.U_CORD_off{idat});
        % --- DURA ---
        [dat.U_DURA{idat}, dat.Q_DURA{idat}, dat.mean_U_DURA{idat}] = ...
            apply_offset(dat.U_DURA{idat}, dat.ROI_DURA{idat}, ...
                                             dat.area_DURA{idat}, onepxarea{idat}, ...
                                             dat.U_DURA_off{idat});

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

function dat = apply_ROI_compute_Q(dat, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter)

    Ndat = dat.Ndat;
    fcal_H_cm_px = dat.fcal_H_cm_px;
    fcal_V_cm_px = dat.fcal_V_cm_px;
    Nt   = dat.Nt;
    venc = dat.venc;
    ROI_SAS  = dat.ROI_SAS;
    ROI_CORD  = dat.ROI_CORD;
    ROI_DURA  = dat.ROI_DURA;
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
    px_area_CORD = cell(Ndat,1);
    px_area_DURA  = cell(Ndat,1);
    px_area_TONS = cell(Ndat,1);

    area_SAS  = cell(Ndat,1);
    area_CORD = cell(Ndat,1);
    area_DURA  = cell(Ndat,1);
    area_TONS = cell(Ndat,1);

    U_SAS  = cell(Ndat,1);
    U_CORD = cell(Ndat,1);
    U_DURA  = cell(Ndat,1);
    U_TONS = cell(Ndat,1);

    U_SAS_off  = cell(Ndat,1);
    U_CORD_off  = cell(Ndat,1);
    U_DURA_off  = cell(Ndat,1);
    U_TONS_off = cell(Ndat,1);

    Q_SAS  = cell(Ndat,1);
    Q_CORD = cell(Ndat,1);
    Q_DURA  = cell(Ndat,1);
    Q_TONS = cell(Ndat,1);

    mean_U_SAS  = cell(Ndat,1);
    mean_U_CORD = cell(Ndat,1);
    mean_U_DURA  = cell(Ndat,1);
    mean_U_TONS = cell(Ndat,1);

    

    outlier_masks = cell(Ndat,1);          
    outlier_masks_tons = cell(Ndat,1);     

    for idat = 1:Ndat

        onepxarea{idat} = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

        % --- pixel counts (logical masks assumed) ---
        px_area_SAS{idat}  = sum(sum(ROI_SAS{idat}));
        px_area_CORD{idat}  = sum(sum(ROI_CORD{idat}));
        px_area_DURA{idat}  = sum(sum(ROI_DURA{idat}));
        px_area_TONS{idat} = sum(sum(ROI_TONS{idat}));

        % --- physical areas (cm^2) ---
        area_SAS{idat}  = px_area_SAS{idat}  * onepxarea{idat};
        area_CORD{idat}  = px_area_CORD{idat}  * onepxarea{idat};
        area_DURA{idat}  = px_area_DURA{idat}  * onepxarea{idat};
        area_TONS{idat} = px_area_TONS{idat} * onepxarea{idat};

        % --- region-masked velocity volumes ---
        U_SAS{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_CORD{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_DURA{idat}  = zeros(size(U_tot{idat}), 'like', U_tot{idat});
        U_TONS{idat} = zeros(size(U_tot{idat}), 'like', U_tot{idat});

        for it = 1:Nt{idat}
            Ui = U_tot{idat}(:,:,it);
            U_SAS{idat}(:,:,it)  = Ui .* ROI_SAS{idat};
            U_CORD{idat}(:,:,it)  = Ui .* ROI_CORD{idat};
            U_DURA{idat}(:,:,it)  = Ui .* ROI_DURA{idat};
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
            % If you also want CORD/DURA smoothed, uncomment:
            % [U_CORD{idat}, ~] = smooth_spatial_outliers_3D(U_CORD{idat}, threshold);
            % [U_DURA{idat}, ~] = smooth_spatial_outliers_3D(U_DURA{idat}, threshold);
        end

        % === Compute flow rates and mean velocities ===
        Q_SAS{idat}  = zeros(1, Nt{idat});
        Q_CORD{idat}  = zeros(1, Nt{idat});
        Q_DURA{idat}  = zeros(1, Nt{idat});
        Q_TONS{idat} = zeros(1, Nt{idat});

        mean_U_SAS{idat}  = zeros(1, Nt{idat});
        mean_U_CORD{idat}  = zeros(1, Nt{idat});
        mean_U_DURA{idat}  = zeros(1, Nt{idat});
        mean_U_TONS{idat} = zeros(1, Nt{idat});

        for it = 1:Nt{idat}
            % optional gaussian smoothing (space) — applied to SAS and TONS
            if gauss_filter
                U_SAS{idat}(:,:,it)  = imgaussfilt(U_SAS{idat}(:,:,it),  0.8);
                U_TONS{idat}(:,:,it) = imgaussfilt(U_TONS{idat}(:,:,it), 0.8);
                % If desired, also:
                % U_CORD{idat}(:,:,it)  = imgaussfilt(U_CORD{idat}(:,:,it),  0.8);
                % U_DURA{idat}(:,:,it)  = imgaussfilt(U_DURA{idat}(:,:,it),  0.8);
            end

            Q_SAS{idat}(it)  = sum(sum(U_SAS{idat}(:,:,it)))  * onepxarea{idat};
            Q_CORD{idat}(it)  = sum(sum(U_CORD{idat}(:,:,it)))  * onepxarea{idat};
            Q_DURA{idat}(it)  = sum(sum(U_DURA{idat}(:,:,it)))  * onepxarea{idat};
            Q_TONS{idat}(it) = sum(sum(U_TONS{idat}(:,:,it))) * onepxarea{idat};

            % means: guard divide-by-zero (empty masks)
            if area_SAS{idat}  > 0, mean_U_SAS{idat}(it)  = Q_SAS{idat}(it)  / area_SAS{idat};  else, mean_U_SAS{idat}(it)  = NaN; end
            if area_CORD{idat}  > 0, mean_U_CORD{idat}(it)  = Q_CORD{idat}(it)  / area_CORD{idat};  else, mean_U_CORD{idat}(it)  = NaN; end
            if area_DURA{idat}  > 0, mean_U_DURA{idat}(it)  = Q_DURA{idat}(it)  / area_DURA{idat};  else, mean_U_DURA{idat}(it)  = NaN; end
            if area_TONS{idat} > 0, mean_U_TONS{idat}(it) = Q_TONS{idat}(it) / area_TONS{idat}; else, mean_U_TONS{idat}(it) = NaN; end
        end

        t_T = linspace(0,1,Nt{idat});

        U_SAS_off{idat}  = simps(t_T, mean_U_SAS{idat}, 2);
        U_CORD_off{idat}  = simps(t_T, mean_U_CORD{idat}, 2);
        U_DURA_off{idat}  = simps(t_T, mean_U_DURA{idat}, 2);
        U_TONS_off{idat} = simps(t_T, mean_U_TONS{idat}, 2);

    end

    % === Assign outputs ===
    dat.onepxarea   = onepxarea;

    % keep original alias map name (SAS) and add tonsils
    dat.pxpos_alias       = pxpox_alias;        % SAS alias mask
    dat.pxpos_alias_tons  = pxpos_alias_tons;   % TONS alias mask

    dat.px_area_SAS  = px_area_SAS;
    dat.px_area_CORD = px_area_CORD;
    dat.px_area_DURA  = px_area_DURA;
    dat.px_area_TONS = px_area_TONS;

    dat.area_SAS  = area_SAS;
    dat.area_CORD = area_CORD;
    dat.area_DURA  = area_DURA;
    dat.area_TONS = area_TONS;

    dat.U_SAS  = U_SAS;
    dat.U_CORD = U_CORD;
    dat.U_DURA  = U_DURA;
    dat.U_TONS = U_TONS;

    dat.U_SAS_off  = U_SAS_off;
    dat.U_CORD_off  = U_CORD_off;
    dat.U_DURA_off  = U_DURA_off;
    dat.U_TONS_off = U_TONS_off;

    dat.Q_SAS  = Q_SAS;
    dat.Q_CORD = Q_CORD;
    dat.Q_DURA  = Q_DURA;
    dat.Q_TONS = Q_TONS;

    dat.mean_U_SAS  = mean_U_SAS;
    dat.mean_U_CORD = mean_U_CORD;
    dat.mean_U_DURA  = mean_U_DURA;
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



function dat = compute_SVQ_zc(dat)
    
    Ndat = dat.Ndat;
    T    = dat.T;
    t_ip = dat.t_ip;
    
    Q_SAS_ip    = dat.Q_SAS_ip;
    Q_SAS_repip = dat.Q_SAS_repip;

    for idat = 1:Ndat

        SVQ_SAS{idat} = 0.5*trapz(t_ip{idat}, abs(Q_SAS_ip{idat}));

        zc_SAS{idat} = trapz(t_ip{idat}, Q_SAS_ip{idat}) / T{idat};
        
        Q_SAS_ip_zc{idat}    = Q_SAS_ip{idat}    - zc_SAS{idat};
        Q_SAS_repip_zc{idat} = Q_SAS_repip{idat} - zc_SAS{idat};
        
        SVQ_SAS_zc{idat} = 0.5*trapz(t_ip{idat}, abs(Q_SAS_ip_zc{idat}));

    end
    
    dat.zc_SAS = zc_SAS;

    dat.SVQ_SAS    = SVQ_SAS;
    dat.SVQ_SAS_zc = SVQ_SAS_zc;

    dat.Q_SAS_ip_zc    = Q_SAS_ip_zc;
    dat.Q_SAS_repip_zc = Q_SAS_repip_zc;

end