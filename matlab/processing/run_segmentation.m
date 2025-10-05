function run_segmentation(subject)
% RUN_SEGMENTATION(subject)
% - Finds the anatomy DICOM folder under patient-data/<subject>/anatomy
% - Converts DICOMs to NIfTI (if needed)
% - Runs SCT auto-segmentation (if needed)
% - Launches Slicer3D post-processing
%
% Assumes organize_flow_anatomy(subject) (or equivalent) already created
% patient-data/<subject>/anatomy/<series_desc> with DICOMs inside.

    fprintf('\n2) Segmentation CSF space...\n')

    % ---------------- Paths & constants ----------------
    dir_chiari        = full_path(fullfile(pwd,'..', '..'));
    anatomy_root      = full_path(fullfile(dir_chiari,'patient-data', subject, 'anatomy'));
    segmentation_path = full_path(fullfile(dir_chiari, 'computations','segmentation',subject));

    if exist(fullfile(segmentation_path, 'stl','segmentation.stl'),'file')
        if askYN('-Segmentation already exist. Skip? ([y]/n): ')
            return;
        end
    end

    createDirIfNotExists(segmentation_path);
    auto_seg_name = "auto_segmentation";
    nii_file      = fullfile(segmentation_path, auto_seg_name + ".nii.gz");

    % ---------------- Find anatomy DICOM folder ----------------
    if ~isfolder(anatomy_root)
        error('Anatomy folder not found: %s', anatomy_root);
    end

    sub = dir(anatomy_root);
    sub = sub([sub.isdir] & ~ismember({sub.name},{'.','..'}));

    if isempty(sub)
        error('No series folder inside anatomy: %s', anatomy_root);
    elseif numel(sub) == 1
        anatomy_dicom = fullfile(sub(1).folder, sub(1).name);
        fprintf('-Using anatomy series: %s\n', sub(1).name);
    else
        fprintf('-Available anatomy series:\n');
        for i = 1:numel(sub)
            fprintf('%2d) %s\n', i, sub(i).name);
        end
        idx = askInt('-Select anatomy series number: ', 1, numel(sub));
        anatomy_dicom = fullfile(sub(idx).folder, sub(idx).name);
    end

    % ---------------- DICOM -> NIfTI ----------------
    if ~isfile(nii_file)
        status = system("dcm2niix -o " + segmentation_path + ...
                        " -f " + auto_seg_name + " -z y " + anatomy_dicom);
        if status == 0
            disp("-Conversion DICOM to NIfTI completed.");
        else
            error("-Error: DICOM->NIfTI conversion failed.");
        end
    else
        disp("-NIfTI file already exists. Skipping conversion.");
    end

    % ---------------- Automated segmentation (SCT) ----------------
    if ~isfile(fullfile(segmentation_path, auto_seg_name + "_seg.nii.gz"))
        system( "sct_deepseg -task seg_sc_contrast_agnostic -i " + nii_file);
        system( "sct_deepseg -task canal_t2w -i " + nii_file);
        system( "sct_deepseg -task seg_spinal_rootlets_t2w -i " + nii_file);
    else
        disp("-Automated segmentation already exists...");
    end
    disp("-Running Slicer3D...")
    % ---------------- Slicer3D post-processing ----------------
    python_script = full_path(fullfile(dir_chiari,'git-chiari', 'slicer3D-code','segmentation.py'));
    system("slicer3D  --python-script """ + python_script + """ """ + subject + """ """ + dir_chiari + """");

    resp = '';
    while ~strcmpi(resp,'ok')
        resp = input('Type "ok" to continue: ','s');
    end

end

% ---------------- helpers (local) ----------------
function createDirIfNotExists(dirPath)
    if ~isfolder(dirPath), mkdir(dirPath); end
end

function absolutePath = full_path(folder_path)
    absolutePath = char(java.io.File(folder_path).getCanonicalPath());
end

function v = askInt(prompt, lo, hi)
    v = input(prompt);
    while ~(isscalar(v) && isnumeric(v) && isfinite(v) && v==floor(v) && v>=lo && v<=hi)
        v = input(sprintf('Enter an integer in [%d, %d]: ', lo, hi));
    end
end
