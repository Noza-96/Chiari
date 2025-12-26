function cas = main_2_segmentation(cas, skip_segmentation)
% RUN_SEGMENTATION(subject)
% - Finds the anatomy DICOM folder under patient-data/<subject>/anatomy
% - Converts DICOMs to NIfTI 
% - Runs SCT auto-segmentation
% - Launches Slicer3D to create manual segmentations

    if skip_segmentation == true, return, end

    auto_seg_name = "auto_segmentation";

    fprintf('\n2) Segmentation CSF space:\n')

    if exist(fullfile(cas.dir.seg, 'stl','segmentation.stl'),'file')
        if askYN('- Segmentation already exist. Skip? ([y]/n): ')
            return;
        end
    end

    nii_file = fullfile(full_path(cas.dir.seg), auto_seg_name + ".nii.gz");

    % ---------------- Find anatomy DICOM folder ----------------

    sub = dir(full_path(cas.dir.anatomy));
    sub = sub([sub.isdir] & ~ismember({sub.name},{'.','..'}));

    if isempty(sub)
        error('No series folder inside anatomy: %s', cas.dir.anatomy);
    elseif numel(sub) == 1
        anatomy_dicom = fullfile(sub(1).folder, sub(1).name);
        fprintf('- Using anatomy series: %s\n', sub(1).name);
    else
        fprintf('-  Available anatomy series:\n');
        for i = 1:numel(sub)
            fprintf('%2d) %s\n', i, sub(i).name);
        end
        idx = askInt('- Select anatomy series number: ', 1, numel(sub));
        anatomy_dicom = fullfile(sub(idx).folder, sub(idx).name);
    end

    % ---------------- DICOM -> NIfTI ----------------
    if ~isfile(nii_file)
        dcm_nif_path = fullfile(config_path('dcm2niix', fullfile(cas.dir.chiari, 'config_file.txt')));
        if dcm_nif_path~="dcm2niix"
            dcm_nif_path = """" + fullfile(dcm_nif_path, "dcm2niix") + """";
        end
        cmd = dcm_nif_path + " -o " + full_path(cas.dir.seg) + " -f " + auto_seg_name + " -z y " + anatomy_dicom;
        status = system(cmd);
        if status == 0
            disp("- Conversion DICOM to NIfTI completed.");
        else
            error("- Error: DICOM->NIfTI conversion failed.");
        end
    else
        disp("- NIfTI file already exists. Skipping conversion.");
    end
    sct_name = "sct_deepseg";
    sct_path = fullfile(config_path(sct_name, fullfile(cas.dir.chiari, 'config_file.txt')));
    if sct_path~=sct_name
        sct_path = fullfile(sct_path, sct_name);
    end
    [~,version_sct] = system("where " + sct_name);
    version_sct = str2double(regexp(version_sct, '(?<=sct_)\d+\.?\d*', 'match', 'once'));
    % ---------------- Automated segmentation (SCT) ----------------
    if ~isfile(fullfile(cas.dir.seg, auto_seg_name + "_seg.nii.gz"))
        if version_sct < 7
            system( sct_path + " -task seg_sc_contrast_agnostic -i " + nii_file);
            system( sct_path + " -task canal_t2w -i " + nii_file);
        else
            system( sct_path + " spinalcord -i " + nii_file);
            system( sct_path + " sc_canal_t2 -i " + nii_file);
        end
    else
        disp("- Automated segmentation already exists...");
    end
    disp("- Running Slicer3D...")

    % ---------------- Slicer3D ----------------
    python_script = fullfile(full_path(cas.dir.git), 'slicer3D-code', 'segmentation.py');

    run_slicer_python(cas, python_script)

end

% ---------------- helpers (local) ----------------

function v = askInt(prompt, lo, hi)
    v = input(prompt);
    while ~(isscalar(v) && isnumeric(v) && isfinite(v) && v==floor(v) && v>=lo && v<=hi)
        v = input(sprintf('Enter an integer in [%d, %d]: ', lo, hi));
    end
end
