function dat = read_dicoms_FM(cas)

    Ndat = length(cas.folders_FM_);
    
    for idat = 1:Ndat
        
        dicomlist = dir(fullfile([cas.dirdcm, '/', cas.folders_FM_{idat}], '*.dcm'));
        
        numim = numel(dicomlist);

        % Run through all files and collect useful headers and image matrices:

        for jj = 1:numim

            fname = fullfile([cas.dirdcm, '/', cas.folders_FM_{idat}], dicomlist(jj).name);

            info{idat}{jj} = dicominfo(fname);

            location{idat}(jj) = double(info{idat}{jj}.(dicomlookup('0020', '1041'))) / 10.0;

            pixspacing = double(info{idat}{jj}.(dicomlookup('0028', '0030')));

            fcal_V_cm_px{idat}(jj) = pixspacing(1) / 10.0;
            fcal_H_cm_px{idat}(jj) = pixspacing(2) / 10.0;

            im_unsorted{idat}{jj} = double(dicomread(info{idat}{jj}));

            acqnum{idat}(jj) = info{idat}{jj}.AcquisitionNumber;
            
            acqmatrix = info{idat}{jj}.AcquisitionMatrix;
            acqmatrixsize{idat}(jj) = acqmatrix(1);
            slicethickness{idat}(jj) = info{idat}{jj}.SliceThickness;
            repetitiontime{idat}(jj) = info{idat}{jj}.RepetitionTime;
            spacingbetweenslices{idat}(jj) = info{idat}{jj}.SpacingBetweenSlices;

        end

        [dummy, sortind] = sortrows([acqnum{idat}.'], [1]);

            info_unsorted{idat} = info{idat};

        for jj = 1:numim

            info{idat}{jj} = info_unsorted{idat}{sortind(jj)};
            im{idat}{jj} = im_unsorted{idat}{sortind(jj)};
            imfm{idat}(:, :, jj) = im{idat}{jj};
            i1fm{idat}(:, :, jj) = imfm{idat}(1:acqmatrixsize{idat}(jj), 1:acqmatrixsize{idat}(jj), jj);

            location{idat}(:)     = location{idat}(sortind);
            fcal_V_cm_px{idat}(:) = fcal_V_cm_px{idat}(sortind);
            fcal_H_cm_px{idat}(:) = fcal_H_cm_px{idat}(sortind);
            acqmatrixsize{idat}(:) = acqmatrixsize{idat}(sortind);
            slicethickness{idat}(:) = slicethickness{idat}(sortind);
            repetitiontime{idat}(:) = repetitiontime{idat}(sortind);
            spacingbetweenslices{idat}(:) = spacingbetweenslices{idat}(sortind);

        end
        
        Nt{idat} = numim;

        locz{idat} = -location{idat};
        
    end
    
    dat.Ndat = Ndat;
    dat.locz = locz;
    dat.Nt   = Nt;

    dat.location = location;
    dat.fcal_H_cm_px = fcal_H_cm_px;
    dat.fcal_V_cm_px = fcal_V_cm_px;
    dat.acqmatrixsize = acqmatrixsize;
    dat.slicethickness = slicethickness;
    dat.repetitiontime = repetitiontime;
    dat.spacingbetweenslices = spacingbetweenslices;

    dat.imfm = imfm;
    dat.i1fm = i1fm;
    
end
