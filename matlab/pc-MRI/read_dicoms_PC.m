function dat = read_dicoms_PC(cas, resettimevector)

    Ndat = length(cas.folders_PC);

    % Get data for each case and store in cell structures were first dimension is case number:

    for idat = 1:Ndat
        
        disp([cas.dirdcm, '/', cas.folders_PC_P{idat}]);
        
        dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_P{idat}], '*.dcm'));

        numim = numel(dicomlist);

        % Run through all files and collect useful headers and image matrices:

        for jj = 1:numim

            fname = fullfile([cas.dirdcm, '/', cas.folders_PC_P{idat}], dicomlist(jj).name);

            % Hack to find VENC:
            command = sprintf('awk ''/^sAngio.sFlowArray.asElm\\[0\\].nVelocity/'' %s', fname);
            [status, sysout] = system(command);
            sysout = erase(sysout, "sAngio.sFlowArray.asElm[0].nVelocity");
            sysout = erase(sysout, "=");
            sysout = sysout(find(~isspace(sysout)));
            venc{idat}(jj) = str2num(sysout);

            % Hack to find RR:
            % Note: unnecessary, RR is simply last time plus delta t; this is later
            % computed as T.
            %[status, sysout] = system( sprintf('strings %s | awk ''/RR/''', fname) );
            %sysout = sysout(find(~isspace(sysout)));
            %sysout = extractAfter(sysout, "RR");
            %sysout = extractBefore(sysout, "+");
            %RR{idat}(jj) = str2num(sysout);

            info{idat}{jj} = dicominfo(fname);

            if isfield(info{idat}{jj}, 'TriggerTime') == 1
                triggertime{idat}(jj) = info{idat}{jj}.(dicomlookup('0018', '1060'));
            else
                disp("No TriggerTime dicom field, using 0.0!")
                triggertime{idat}(jj) = 0.0;
            end
            
            location{idat}(jj) = double(info{idat}{jj}.(dicomlookup('0020', '1041'))) / 10.0;

            pixspacing = double(info{idat}{jj}.(dicomlookup('0028', '0030')));

            fcal_V_cm_px{idat}(jj) = pixspacing(1) / 10.0;
            fcal_H_cm_px{idat}(jj) = pixspacing(2) / 10.0;

            im_unsorted{idat}{jj} = double(dicomread(info{idat}{jj}));

        end

        % Load DICOM files with magnitude out of parallel directory for complementary use:
        
        if isempty(cas.folders_PC_MAG) == 1
            
            display("Magnitude images do not exist.")

            % Set magnitude images to zero.

            for jj = 1:numim
                
                immag_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
                
            end

        else

            dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], '*.dcm'));

            numim = numel(dicomlist);

            fname_showorient{idat} = fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], dicomlist(1).name);

            for jj = 1:numim

                fname = fullfile([cas.dirdcm, '/', cas.folders_PC_MAG{idat}], dicomlist(jj).name);

                infomag{idat}{jj} = dicominfo(fname);

                immag_unsorted{idat}{jj} = double(dicomread(infomag{idat}{jj}));

            end

        end

        % Load DICOM files with stuff out of parallel directory for complementary use:

        dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_PC_{idat}], '*.dcm'));

        numim = numel(dicomlist);

        for jj = 1:numim

            fname = fullfile([cas.dirdcm, '/', cas.folders_PC_{idat}], dicomlist(jj).name);

            infocom{idat}{jj} = dicominfo(fname);

            imcom_unsorted{idat}{jj} = double(dicomread(infocom{idat}{jj}));

        end

        % Sort images as pairs by triggertime:

        [dummy, sortind] = sortrows([triggertime{idat}.'], [1]);

        venc{idat}(:)         = venc{idat}(sortind);
        triggertime{idat}(:)  = triggertime{idat}(sortind);
        location{idat}(:)     = location{idat}(sortind);
        fcal_V_cm_px{idat}(:) = fcal_V_cm_px{idat}(sortind);
        fcal_H_cm_px{idat}(:) = fcal_H_cm_px{idat}(sortind);

        % these do not change in a time series so we only keep one:

        venc{idat} = venc{idat}(1);
        location{idat} = location{idat}(1);
        fcal_V_cm_px{idat} = fcal_V_cm_px{idat}(1);
        fcal_H_cm_px{idat} = fcal_H_cm_px{idat}(1);

        for jj = 1:numim
            im{idat}{jj}    = im_unsorted{idat}{sortind(jj)};
            immag{idat}{jj} = immag_unsorted{idat}{sortind(jj)};
            imcom{idat}{jj} = imcom_unsorted{idat}{sortind(jj)};
        end

        for jj = 1:numim

            % Save the acquisition times in seconds:

            t{idat}(jj) = double(triggertime{idat}(jj)) / 1000.0;

            % Save the phase and magnitude images:

            phase{idat}(:, :, jj) = im{idat}{jj};
            magni{idat}(:, :, jj) = immag{idat}{jj};
            compl{idat}(:, :, jj) = imcom{idat}{jj};

            % Convert image pairs to velocity fields in cm/s (Note: positive is craniocaudal flow):

            U_tot{idat}(:, :, jj) = - venc{idat} .* ( (phase{idat}(:, :, jj) - 2048) ./ 2048 );

        end

        % We subtract whatever is needed to set the timestamp of the first time to zero:
        
        t{idat}(:) = t{idat}(:) - t{idat}(1);
        
        % Save the number of acquisition times, the length of one period in seconds (can be
        % overridden in step 1B):
        
        Nt{idat} = numim;

        dt{idat} = t{idat}(end)/(Nt{idat}-1);
        
        T{idat} = t{idat}(end) + dt{idat};

        % Sometimes the acquisition does not equispace the time vector.
        % We then set the time vector ourselves:

        if resettimevector
            t{idat}(:) = [0:1:Nt{idat}-1]*dt{idat};
        end
        
        % Save the slice location in cm:

        locz{idat} = -location{idat};
        
    end

    disp(' '); disp(' '); disp(' ')
    disp('List of all cases:')
    for idat = 1:Ndat
        disp([num2str(idat, '%02d'), '  -  ', cas.names{idat}])
    end
    disp(' '); disp(' '); disp(' ');


    % Create figure to visualize locations pc-mri measurements 
    fig = figure;
    segm_path = ""+cas.dirseg+"/stl/segmentation.stl";
    if exist(segm_path, 'file') == 2
        disp("Segmentation exists!")
        gm = importGeometry(segm_path);
        scale(gm,[1,1,1])
        pdegplot(gm)
    else
        disp("There is no segmentation...")
    end
    for idat = 1:Ndat
        DrawImageSlice3D(fname_showorient{idat}, fig, 0.75);
    end
    saveas(fig, [cas.dirfig, '/pc-mri_locations.fig'])
    
    dat.Ndat         = Ndat;
    dat.locz         = locz;
    dat.Nt           = Nt;
    dat.T            = T;
    dat.dt           = dt;
    dat.t            = t;
    dat.U_tot        = U_tot;
    dat.phase        = phase;
    dat.magni        = magni;
    dat.compl        = compl;
    dat.venc         = venc;
    dat.fcal_H_cm_px = fcal_H_cm_px;
    dat.fcal_V_cm_px = fcal_V_cm_px;

end

