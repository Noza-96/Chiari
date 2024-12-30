function write_fourier(cas, dat, idat_sel)
    
    dirmatfou = [cas.dirmat, '/fou'];

    if not(isfolder(dirmatfou))
        mkdir(dirmatfou)
    end

    M = dat.fou.M;
    
    k = 0;
    for idat = idat_sel
        k = k + 1;
        locd(k) = dat.locd{idat};
        area(k) = dat.area_SAS{idat};
        fm(k, 1:M) = dat.fou.fm{idat};
        am(k, 1:M) = dat.fou.am{idat};
    end
    
    writematrix(locd.', [dirmatfou, '/position.dat']);
    writematrix(area.', [dirmatfou, '/area.dat']);
    
    writematrix(fm, [dirmatfou, '/fm.dat']);

    writematrix(real(am), [dirmatfou, '/am_r.dat']);
    writematrix(imag(am), [dirmatfou, '/am_i.dat']);
    
    writematrix(M, [dirmatfou, '/M.dat']);

end