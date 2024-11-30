function comparison_results(subject,cas,dat_PC)
    disp('3. Animation comparing ansys velocity results with PC-MRI measurements:')

    % Open the file
    load("data\"+subject+"\ansys_outputs\DNS.mat",'DNS');
    figure
    tit=tiledlayout(5,3,"TileSpacing","tight","Padding","loose");
    set(gcf,'pos',[100,000,1000,1000])
    %For each time-step
    for n=1:100
        % We do it for each PC-MRI measurement
        create_animation_MRI(dat_PC,n)
        % We do it for Uniform simulation
        create_animation_ansys(DNS.Uniform,n,0)
        % We do it for Variable simulation
        create_animation_ansys(DNS.Variable,n,1)
        title(tit,sprintf('$t/T = %.2f$ ', n/100),'interpreter','latex',fontsize=20);    
        movieVector(n) = getframe(gcf);
        drawnow;
    end
    sstt="2D_velocity_comparisons";
    myWriter = VideoWriter(fullfile('Videos',subject,'post',sstt));
    myWriter.FrameRate = 5;
    open(myWriter);
    writeVideo(myWriter,movieVector);
    close(myWriter);

end

%% Auxiliary functions

function create_animation_MRI(dat_PC,n)
    u_MRI = dat_PC.U_SAS;
    fs=12;
    xL=[200,0];
    yL=xL;
    for k=1:length(u_MRI)
        [Y,X,~]=find(u_MRI{k}(:,:,1));
        DX = (max(X)-min(X)+10)/2;
        X0 = (max(X)+min(X))/2;
        Y0 = (max(Y)+min(Y))/2;
        xL(1)=min(xL(1),X0-DX);
        xL(2)=max(xL(2),X0+DX);
        yL(1)=min(yL(1),Y0-DX);
        yL(2)=max(yL(2),Y0+DX);
    end
    for k=1:length(u_MRI)
        nexttile (4+(k-1)*3)
        imagesc(u_MRI{k}(:,:,n));
        bluetored(6);
        set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        colorbar off;
        if k==length(u_MRI)
            xlabel('X [pixels]','interpreter','latex',FontSize=fs);
            ylabel('Y [pixels]','interpreter','latex',FontSize=fs);
        end
        ylim(yL)
        xlim(xL)
    end
end

function create_animation_ansys(data,n,index)
fs = 12;
    for loc = 1:length(data)
        x = data(loc).x;
        y = data(loc).y;
        % Define the grid points for interpolation (you can adjust the resolution of the grid)
        xq = linspace(min(x), max(x), 1000); % 1000 points in x-direction
        yq = linspace(min(y), max(y), 1000); % 1000 points in y-direction

        % Create a meshgrid from these points
        [Xq, Yq] = meshgrid(xq, yq);

        w = data(loc).w;
        % Interpolate w onto the grid using scattered data
        Zq = griddata(x, y, w(:,n), Xq, Yq, 'cubic');
        
        ax=nexttile(2+index+(loc-1)*3);
        % Plot the contour
        % contourf(Xq, Yq, Zq, 20, 'LineColor', 'none'); % '20' specifies the number of contour levels (adjust as needed)
        scatter(x, y, 8, w(:,n), 'filled', 'd');        
        colorbar; % Add a color bar to indicate the w scale
        if loc == length(data)
            xlabel('X [cm]','interpreter','latex',FontSize=fs);
            ylabel('Y [cm]','interpreter','latex',FontSize=fs);
        end
        set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
        bluetored(6)
        if index == 0
            colorbar off
        end

        box on
        hold off 
        Dx = max(x(:))-min(x(:));
        Dy = max(y(:))-min(y(:));
        % axis equal
        xlim([min(x(:))-Dx*0.1,max(x(:))+Dx*0.1])
        ylim([min(y(:))-Dy*0.1,max(y(:))+Dy*0.1])

        pos = ax.Position;

        if loc == 1
            x_loc = 0;
        end

        if index == 1 & n==1
            y_loc = pos(2)-pos(4)*0.2;
            annotation('textbox', [x_loc, y_loc, 0.09, 0.1], 'String', "\textbf{{"+data(loc).locations+":}}", ...
           'Interpreter', 'latex', 'EdgeColor', 'none','HorizontalAlignment', 'right',FontSize=12);
        end
    end
end
