function plot_Q(aux, cas, dat, save_figs, idat_sel, sffx)
    
    Ndat = dat.Ndat;

    T = dat.T;
    
    tt = dat.t_repip;
    
    QQ = dat.Q_SAS_repip;
    plot_QQ(tt, QQ, 101)

    if save_figs
        fig = gcf;
        saveas(fig, [cas.dirfig, '/Q_', sffx, '.fig'])
        fig.PaperPositionMode = 'auto';
        print([cas.dirfig, '/Q_', sffx, '.png'], '-dpng','-r150')
    end

    QQ = dat.Q_SAS_repip_zc;
    plot_QQ(tt, QQ, 102)

    if save_figs
        fig = gcf;
        saveas(fig, [cas.dirfig, '/Q_', sffx, '_zc.fig'])
        fig.PaperPositionMode = 'auto';
        print([cas.dirfig, '/Q_', sffx, '_zc.png'], '-dpng','-r150')
    end
    
    function plot_QQ(tt, QQ, fh)

        figure(fh)

        set(gcf, aux.fig_opts)
        set(gcf, 'position', [80, 80, 720, 1280])

        Qlim = 1.0;
        DA = 2*3*Qlim;

        kk = 0;

        Nplots = length(idat_sel)

        for idat = idat_sel

            kk = kk + 1;

            ttt = (tt{idat}-T{idat})/T{idat};
            QQQ = QQ{idat};

            indn = QQQ <  0;
            indp = QQQ >= 0;

            subaxis(Nplots, 1, kk, 'SpacingVert', 0.01)
            hold on
            area(ttt(indn), QQQ(indn) , 'Facecolor', aux.klr.b)
            area(ttt(indp), QQQ(indp) , 'Facecolor', aux.klr.r)
            plot(ttt, QQQ, '-', 'Color', 0.2*[1, 1, 1], 'LineWidth', 1.5)
            maxQ = max(abs(QQQ));

            xlim([-0.5, 1.5])
            ylim([-Qlim, Qlim])
            set(gca, 'XTick', [0:0.5:1])
            set(gca, 'YTick', [-Qlim,0,Qlim])
            daspect([1,DA,1])

            if kk == Ndat
                subaxis(Ndat, 1, kk)
                xlabel('cycles', 'Interpreter', 'none', 'fontsize', 10)
            else
                set(gca, 'XTickLabel', [])
            end
            grid on
            box off
            text(1.55, 0.75*Qlim, cas.locations{idat}, 'Interpreter', 'none', 'fontsize', 10, 'fontname', 'helvetica')
            set(gca, 'fontsize', 10, 'fontname', 'helvetica', 'fontweight', 'bold')

        end
        sgtitle('Flow rate in ml/s', 'Interpreter', 'none', 'fontsize', 10, 'fontname', 'helvetica')
        
    end

end