function dat = adjust_periods(dat, vecT)



    for idat = 1:dat.Ndat
        dat.T{idat} = vecT{idat};
    end



end