function dat_PC = adjust_vertical_location_PC(cas, dat_PC, reference_location)

    locations = cas.locations;
    Ndat      = dat_PC.Ndat;
    locz      = dat_PC.locz;
    
    if strcmp(reference_location, 'zero') == 1
        
        disp("Setting all locations to 0.")
        
        for idat = 1:Ndat
            locz{idat} = 0.0;
            locd{idat} = 0.0;
        end
    
    elseif strcmp(reference_location, 'original') == 1
        
        disp("Using original locations.")
        
        for idat = 1:Ndat
            locz{idat} = locz{idat};
            locd{idat} = locz{idat};
        end
        
    elseif strcmp(reference_location, 'fromsag') == 1
        
        if exist([cas.dirgeo, '/geomdata.mat']) == 0
            
            disp("File geomdata.mat not found! Using original locations.")
            
            for idat = 1:Ndat
                locz{idat} = locz{idat};
                locd{idat} = locz{idat};
            end
            
        else
            
            % We load the geometry data of the specific subject (in mm):
            geo = load([cas.dirgeo, '/geomdata.mat']).geomdata;

            % Plot locations:
            figure(881)
            subplot(1, 2, 1)
            for idat = 1:Ndat
                plot(0, locz{idat}, 'ro', 'MarkerFaceColor', 'r')
                hold on
                text(1, locz{idat}, locations{idat}, 'Color', 'r', 'FontSize', 8, 'FontWeight', 'bold')
                hold on
                plot(0, geo.(strcat('z', locations{idat})),  'k^', 'MarkerFaceColor', 'k')
                hold on
                text(1, geo.(strcat('z', locations{idat})), locations{idat}, 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold')
                hold on
                grid on
                xlim([-10, 10])
                ylim([-10, 80])
                set(gca, 'yDir', 'reverse')
                grid minor
            end
            
            for idat = 1:Ndat
                locz{idat} = geo.(strcat('z', locations{idat}));
                locd{idat} = geo.convert_z2d(locz{idat});
            end

            % Plot locations:
            figure(881)
            subplot(1, 2, 2)
            for idat = 1:Ndat
                plot(0, locz{idat}, 'bo', 'MarkerFaceColor', 'b')
                hold on
                text(1, locz{idat}, locations{idat}, 'Color', 'b', 'FontSize', 8, 'FontWeight', 'bold')
                hold on
                plot(0, geo.(strcat('z', locations{idat})),  'k^', 'MarkerFaceColor', 'k')
                hold on
                text(1, geo.(strcat('z', locations{idat})), locations{idat}, 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold')
                hold on
                grid on
                xlim([-10, 10])
                ylim([-10, 80])
                set(gca, 'yDir', 'reverse')
                grid minor
            end
            fig = gcf;
            saveas(fig, [cas.dirfig, '/locations.fig'])
            fig.PaperPositionMode = 'auto';
            print([cas.dirfig, '/locations.png'], '-dpng','-r300')
            
        end
        
    else
        
            
        for idat = 1:Ndat
            locz{idat} = locz{idat};
            locd{idat} = locz{idat};
        end

    end
    
    close all

    dat_PC.locz = locz;
    dat_PC.locd = locd;

end
