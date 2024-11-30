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
        
        %figure(99)
        %clf
        %hold on
        %plot(t_ip{idat}, Q_SAS_ip{idat}, 'k-')
        %plot(t_ip{idat}, Q_SAS_ip_zc{idat}, 'r-')
        %pause

    end
    
    dat.zc_SAS = zc_SAS;

    dat.SVQ_SAS    = SVQ_SAS;
    dat.SVQ_SAS_zc = SVQ_SAS_zc;

    dat.Q_SAS_ip_zc    = Q_SAS_ip_zc;
    dat.Q_SAS_repip_zc = Q_SAS_repip_zc;

end