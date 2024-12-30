function dat = apply_ROI_compute_Q(dat)
    
    correct_aliasing = true;
    
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

        for it = 1:Nt{idat}
            
            U_SAS{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_SAS{idat};
            U_COR{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_COR{idat};
            U_SPC{idat}(:, :, it) = U_tot{idat}(:, :, it) .* ROI_SPC{idat};
            
            if correct_aliasing
                
                UU = squeeze(U_SAS{idat}(:, :, it));
                
                UU_corr = (venc{idat}/pi) * unwrap_phase((pi/venc{idat}) * UU);

                diffUUcorrUU = double(abs(UU_corr - UU) > 1.0e-6);

                U_SAS_idat_corr(:, :, it) = UU_corr;
                pxpos_alias_idat(:, :, it) = diffUUcorrUU;

            end

            Q_SAS{idat}(it) = sum(sum( U_SAS{idat}(:, :, it) )) * onepxarea{idat};
            Q_COR{idat}(it) = sum(sum( U_COR{idat}(:, :, it) )) * onepxarea{idat};
            Q_SPC{idat}(it) = sum(sum( U_SPC{idat}(:, :, it) )) * onepxarea{idat};

            mean_U_SAS{idat}(it) = Q_SAS{idat}(it) / area_SAS{idat};
            mean_U_COR{idat}(it) = Q_COR{idat}(it) / area_COR{idat};
            mean_U_SPC{idat}(it) = Q_SPC{idat}(it) / area_SPC{idat};
            
        end
        
        U_SAS{idat} = U_SAS_idat_corr;

        pxpox_alias{idat} = pxpos_alias_idat;

    end
    
    dat.onepxarea    = onepxarea;
    
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

end
