function dat = compute_Q_CSF(cas, dat)

    Ndat = dat.Ndat;

    fcal_H_cm_px = dat.fcal_H_cm_px;
    fcal_V_cm_px = dat.fcal_V_cm_px;

    Nt = dat.Nt;

    ROI_CSF_SAS = dat.ROI_CSF_SAS;
    ROI_CSF_COR = dat.ROI_CSF_COR;
    ROI_CSF_SPC = dat.ROI_CSF_SPC;

    U_tot = dat.U_tot;
    
    


    for idat = 1:Ndat
        
        onepxarea{idat} = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};
        
        
        fcal_H_cm_px = dat.fcal_H_cm_px;
        fcal_V_cm_px = dat.fcal_V_cm_px;

        U_CSF_SAS = dat.U_CSF_SAS;
        U_CSF_COR = dat.U_CSF_COR;
        U_CSF_SPC = dat.U_CSF_SPC;
        
        Nt = dat.Nt;
        
        for it = 1:Nt{idat}

            onepxarea_CSF = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

            Q_CSF_SAS{idat}(it) = sum(sum( U_CSF_SAS{idat}(:, :, it) )) * onepxarea_CSF;
            Q_CSF_COR{idat}(it) = sum(sum( U_CSF_COR{idat}(:, :, it) )) * onepxarea_CSF;
            Q_CSF_SPC{idat}(it) = sum(sum( U_CSF_SPC{idat}(:, :, it) )) * onepxarea_CSF;

        end

        % Interpolate and compute Q again, (gives nearly the same results):

        k_IP = 2;

        for it = 1:Nt{idat}

            U_CSF_SAS_IP{idat}(:, :, it) = interp2(U_CSF_SAS{idat}(:, :, it), k_IP, 'cubic');
            U_CSF_COR_IP{idat}(:, :, it) = interp2(U_CSF_COR{idat}(:, :, it), k_IP, 'cubic');
            U_CSF_SPC_IP{idat}(:, :, it) = interp2(U_CSF_SPC{idat}(:, :, it), k_IP, 'cubic');

            onepxarea_CSF_IP = fcal_H_cm_px{idat} * fcal_V_cm_px{idat} / 4^k_IP;

            Q_CSF_SAS_IP{idat}(it) = sum(sum( U_CSF_SAS_IP{idat}(:, :, it) )) * onepxarea_CSF_IP;
            Q_CSF_COR_IP{idat}(it) = sum(sum( U_CSF_COR_IP{idat}(:, :, it) )) * onepxarea_CSF_IP;
            Q_CSF_SPC_IP{idat}(it) = sum(sum( U_CSF_SPC_IP{idat}(:, :, it) )) * onepxarea_CSF_IP;

        end

    end
    
    dat.Q_CSF_SAS = Q_CSF_SAS;
    dat.Q_CSF_COR = Q_CSF_COR;
    dat.Q_CSF_SPC = Q_CSF_SPC;

    dat.Q_CSF_SAS_IP = Q_CSF_SAS_IP;
    dat.Q_CSF_COR_IP = Q_CSF_COR_IP;
    dat.Q_CSF_SPC_IP = Q_CSF_SPC_IP;

end