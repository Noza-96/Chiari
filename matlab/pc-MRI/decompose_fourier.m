function dat = decompose_fourier(cas, dat)

    Ndat = dat.Ndat;
    T    = dat.T;
    t    = dat.t_ip;
    Q    = dat.Q_SAS_ip;
    N1   = dat.Nt_ip;
    dt   = dat.dt_ip;
    Nrep = 4;
    M    = 30;
    
    for idat = 1:Ndat
        
        TT  = T{idat};
        tt  = t{idat};
        QQ  = Q{idat};
        dtt = dt{idat};

        tt(end) = []; % (we start at 0, but stop one dt before T)
        QQ(end) = []; % (we start at 0, but stop one dt before T)

        if length(tt) ~= N1
            disp("Error in the lengths!")
        end

        ttt = tt;
        QQQ = QQ;
        
        for irep = 1:Nrep-1
            
            ttt = [ttt, tt + irep*TT];
            QQQ = [QQQ, QQ];
            
        end
        
        zi = sqrt(-1.0);

        L  = Nrep*N1;
        Fs = N1*2*pi/TT;
        f  = Fs*(0:(L/2))/L;
        Y  = fft(QQQ);
        P2 = Y/L;
        P  = P2(1:L/2+1);
        a0 = P(1);

        for m = 1:M
            fm(m) = f(m*Nrep + 1);
            am(m) = P(m*Nrep + 1);
            %Qm(m) = am(m)/(zi*m); % This was for some paper, not necessary
        end
        
        tF = ttt;
        QF = a0 + zeros(size(tF));
        for m = 1:M
            QF = QF + am(m) * exp(zi*fm(m)*tF) + conj(am(m)) * exp(-zi*fm(m)*tF);
        end

        fmidat{idat} = fm;
        amidat{idat} = am;
        %Qmidat{idat} = Qm;

        figure(401)
        subplot(Ndat, 1, idat)
        hold on
        plot(ttt, QQQ, 'k-', 'LineWidth', 2)
        plot(tF,  QF, 'r--', 'LineWidth', 2)
        xlim([0, TT])
        drawnow

    end

    disp("Paused... hit enter.")
    pause
    
    dat.fou.M  = M;
    dat.fou.fm = fmidat;
    dat.fou.am = amidat;
    %dat.fou.Qm = Qmidat;
    
end
