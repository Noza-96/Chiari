function define_ROI_CSF(cas, dat)



    for idat = 1:dat.Ndat;

        [Ny, Nx] = size(dat.U_tot{idat}(:, :, 1));

        for iy = 1:Ny
            for ix = 1:Nx
                Fs = dat.Nt{idat}/dat.T{idat};
                L  = dat.Nt{idat};
                tt = dat.t{idat};
                UU = squeeze(dat.U_tot{idat}(iy, ix, :)).';
                [f, P1] = get_fft_at_point(tt, UU, Fs, L);
                FCU(iy, ix, 1:L/2+1) = P1(1:L/2+1);
            end
        end

        FCUmo23 = sum(FCU(:, :, 2:3), 3);
        FCUrest = FCU(:, :, 1) + sum(FCU(:, :, 5:end), 3);

        ROI{idat} = imgaussfilt(FCUmo23./FCUrest, 1.0);

        level{idat} = graythresh(ROI{idat});

        ROIBW{idat} = imbinarize(ROI{idat}, level{idat});

        B = bwboundaries(ROIBW{idat}, 8, 'holes')


        figure(101)
        clf
        imshow(ROI{idat})
        hold on
        for k = 1:length(B)
            boundary = B{k};
            boundary = fliplr(boundary);
            plot(boundary(:,1), boundary(:,2), 'r', 'LineWidth', 2)
            drawfreehand('Position', boundary)
        end
        pause


        %figure(101)
        %clf
        %imshow(ROIBW{idat})
        %hold on
        %for k = 1:length(B)
        %    boundary = B{k};
        %    boundary = fliplr(boundary);
        %    plot(boundary(:,1), boundary(:,2), 'r', 'LineWidth', 2)
        %    drawfreehand('Position', boundary)
        %end
        %pause


    end



    function [f, P1] = get_fft_at_point(tt, UU, Fs, L)
        Y  = fft(UU);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(L/2))/L;
    end



end