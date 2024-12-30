function dat = repeat_interpolate_Q(dat)

    Ndat = dat.Ndat;
    
    t  = dat.t;
    T  = dat.T;
    Nt = dat.Nt;
    
    Q_SAS = dat.Q_SAS;
    Q_COR = dat.Q_COR;
    Q_SPC = dat.Q_SPC;

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
        Q_COR_rep{idat} = [repmat(Q_COR{idat}, [1, Nrep]), Q_SAS{idat}(1)];
        Q_SPC_rep{idat} = [repmat(Q_SPC{idat}, [1, Nrep]), Q_SAS{idat}(1)];

        % Then interpolate on dense grid:
        
        t_repip{idat} = linspace(t_rep{idat}(1), t_rep{idat}(end), Nrep*Nt_ip + 1);
        
        Q_SAS_repip{idat} = interp1(t_rep{idat}, Q_SAS_rep{idat}, t_repip{idat}, 'makima');
        Q_COR_repip{idat} = interp1(t_rep{idat}, Q_COR_rep{idat}, t_repip{idat}, 'makima');
        Q_SPC_repip{idat} = interp1(t_rep{idat}, Q_SPC_rep{idat}, t_repip{idat}, 'makima');
        
        % Then take the complete, interpolated, second cycle:

        ind = t_repip{idat} > T{idat}-1.0e-6 & t_repip{idat} < 2.0*T{idat}+1.0e-6;
        
        t_ip{idat} = t_repip{idat}(ind) - T{idat};

        dt_ip{idat} = t_ip{idat}(2) - t_ip{idat}(1);
        
        Q_SAS_ip{idat} = Q_SAS_repip{idat}(ind);
        Q_COR_ip{idat} = Q_COR_repip{idat}(ind);
        Q_SPC_ip{idat} = Q_SPC_repip{idat}(ind);
        
    end
    
    dat.t_rep   = t_rep;

    dat.Q_SAS_rep = Q_SAS_rep;
    dat.Q_COR_rep = Q_COR_rep;
    dat.Q_SPC_rep = Q_SPC_rep;

    dat.t_repip = t_repip;

    dat.Q_SAS_repip = Q_SAS_repip;
    dat.Q_COR_repip = Q_COR_repip;
    dat.Q_SPC_repip = Q_SPC_repip;

    dat.t_ip  = t_ip;
    dat.Nt_ip = Nt_ip;
    dat.dt_ip = dt_ip;

    dat.Q_SAS_ip = Q_SAS_ip;
    dat.Q_COR_ip = Q_COR_ip;
    dat.Q_SPC_ip = Q_SPC_ip;

end
