function cas = run_segmentation(cas)
% RUN_SEGMENTATION(subject)
% - Finds the anatomy DICOM folder under patient-data/<subject>/anatomy
% - Converts DICOMs to NIfTI 
% - Runs SCT auto-segmentation
% - Launches Slicer3D to create manual segmentations

    auto_seg_name = "auto_segmentation";


    fprintf('\n2) Segmentation CSF space:\n')

    if exist(fullfile(cas.dir.seg, 'stl','segmentation.stl'),'file')
        if askYN('- Segmentation already exist. Skip? ([y]/n): ')
            return;
        end
    end

    nii_file = fullfile(cas.dir.seg, auto_seg_name + ".nii.gz");

    % ---------------- Find anatomy DICOM folder ----------------

    sub = dir(cas.dir.anatomy);
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
        status = system(dcm_nif_path + " -o " + cas.dir.seg + ...
                        " -f " + auto_seg_name + " -z y " + anatomy_dicom);
        if status == 0
            disp("- Conversion DICOM to NIfTI completed.");
        else
            error("- Error: DICOM->NIfTI conversion failed.");
        end
    else
        disp("- NIfTI file already exists. Skipping conversion.");
    end

    sct_path = fullfile(config_path('sct_deepseg', fullfile(cas.dir.chiari, 'config_file.txt')));

    % ---------------- Automated segmentation (SCT) ----------------
    if ~isfile(fullfile(cas.dir.seg, auto_seg_name + "_seg.nii.gz"))
        system( sct_path + " -task seg_sc_contrast_agnostic -i " + nii_file);
        system( sct_path + " -task canal_t2w -i " + nii_file);
        system( sct_path + " -task seg_spinal_rootlets_t2w -i " + nii_file);
    else
        disp("- Automated segmentation already exists...");
    end
    disp("- Running Slicer3D...")

    % ---------------- Slicer3D ----------------
    python_script = fullfile(cas.dir.git, 'slicer3D-code', 'segmentation.py');

    run_slicer_python(cas, python_script)

end

% ---------------- helpers (local) ----------------

function v = askInt(prompt, lo, hi)
    v = input(prompt);
    while ~(isscalar(v) && isnumeric(v) && isfinite(v) && v==floor(v) && v>=lo && v<=hi)
        v = input(sprintf('Enter an integer in [%d, %d]: ', lo, hi));
    end
end
