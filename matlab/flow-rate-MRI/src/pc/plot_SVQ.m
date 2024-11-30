function plot_SVQ(aux, cas, dat, save_figs, idat_sel, sffx)
    
    Ndat = dat.Ndat;
    
    locd = [dat.locd{idat_sel}];

    SVQ = [dat.SVQ_SAS{idat_sel}];
    plot_SV(locd, SVQ, 201)

    if save_figs
        fig = gcf;
        saveas(fig, [cas.dirfig, '/SVQ_', sffx, '.fig'])
        fig.PaperPositionMode = 'auto';
        print([cas.dirfig, '/SVQ_', sffx, '.png'], '-dpng','-r150')
    end

    SVQ = [dat.SVQ_SAS_zc{idat_sel}];
    plot_SV(locd, SVQ, 202)

    if save_figs
        fig = gcf;
        saveas(fig, [cas.dirfig, '/SVQ_', sffx, '_zc.fig'])
        fig.PaperPositionMode = 'auto';
        print([cas.dirfig, '/SVQ_', sffx, '_zc.png'], '-dpng','-r150')
    end
    
    function plot_SV(locd, SVQ, fh)

        figure(fh)

        set(gcf, aux.fig_opts)
        set(gcf, 'position', [80, 80, 400, 1280])

        plot(SVQ, locd, ...
            'o-', 'Color', [1.0,0.5,0.5], 'MarkerEdgeColor', [1, 1, 1], 'MarkerFaceColor', [1.0,0.5,0.5])

        axis([0.0, 0.50, -5, 70])

        set(gca, 'XTick', [0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0, 2.25, 2.5])

        set(gca, 'YDir', 'reverse')
        grid on
        box off

        xlabel('stroke volume [ml]')
        ylabel('distance from FM [cm]')
        
    end

end
