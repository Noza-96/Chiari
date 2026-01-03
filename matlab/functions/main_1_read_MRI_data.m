function [cas, dat_PC] = main_1_read_MRI_data(cas)

    fprintf('\n--- Processing subject: %s ---\n\n', cas.subj);

    fprintf('1) Setup subject and extract MRI data:\n')
    %% Create directories
    cas = create_directories(cas);

    data_file = fullfile(cas.dir.mat, 'data_0.mat');

    if exist(data_file,'file')
        if askYN('- MRI data already extracted. Skip? ([y]/n): ')
            load(fullfile(cas.dir.mat, 'data_0.mat'), 'cas', 'dat_PC');
            return;
        end
    end

    %% 
    fprintf('\n- Organize DICOM data...\n')
    cas = organize_DICOMS(cas);

    %% 
    fprintf('\nExtract PC-MRI data...\n')
    [cas, dat_PC] = main_1_read_dat(cas);
    
    %% 
    file_name = "data_0.mat";
    fprintf("\nSaving %s ...\n", file_name)
    save(fullfile(cas.dir.mat, file_name), 'cas','dat_PC');
end


function cas = create_directories(cas)
% - Create directories
    cas.dir.chiari          = fullfile( '..', '..');
    cas.dir.git             = fullfile(cas.dir.chiari,'git-chiari');
    cas.dir.patient         = fullfile(cas.dir.chiari,'patient-data', cas.subj);
    cas.dir.comp            = fullfile(cas.dir.chiari,'computations');
    cas.dir.anatomy         = fullfile(cas.dir.patient, 'anatomy');
    cas.dir.flow            = fullfile(cas.dir.patient, 'flow');
    cas.dir.dat              = fullfile(cas.dir.comp,'pc-mri', cas.subj);
    cas.dir.mat              = fullfile(cas.dir.dat, 'mat');
    cas.dir.aux              = fullfile(cas.dir.mat, 'aux');
    cas.dir.vid              = fullfile(cas.dir.comp, 'videos', cas.subj);
    cas.dir.fig              = fullfile(cas.dir.comp, 'figures', cas.subj);
    cas.dir.ROI              = fullfile(cas.dir.mat,'ROIs');
    cas.dir.ansys            = fullfile(cas.dir.comp, 'ansys', cas.subj);
    cas.dir.ansys_out        = fullfile(cas.dir.ansys, 'outputs');
    cas.dir.ansys_in         = fullfile(cas.dir.ansys, 'inputs');
    cas.dir.ansys_profiles   = fullfile(cas.dir.ansys_in, 'profiles');
    cas.dir.seg              = fullfile(cas.dir.comp, 'segmentation', cas.subj);
    cas.dir.reg              = fullfile(cas.dir.seg, 'registration');
    cas.dir.trans            = fullfile(cas.dir.reg, 'transformation');

    % List of directories to ensure exist
    dirsToCreate = {cas.dir.anatomy, cas.dir.flow, cas.dir.mat, fullfile(cas.dir.mat, 'DNS'), fullfile(cas.dir.mat, 'DNS-results'),... 
        cas.dir.dat, cas.dir.ansys, cas.dir.ansys_out, cas.dir.ansys_in, cas.dir.ansys_profiles, cas.dir.vid, ... 
        cas.dir.seg, cas.dir.fig, cas.dir.reg, cas.dir.trans, fullfile(cas.dir.reg, 'pcMRI'), ... 
        fullfile(cas.dir.reg,'2D-segmentation'), fullfile(cas.dir.reg, 'input-velocity'), fullfile(cas.dir.reg, 'output-velocity'), cas.dir.ROI, fullfile(cas.dir.seg, 'stl'), fullfile(cas.dir.ansys_in, "planes"), fullfile(cas.dir.ansys_in, "flow-rates"), fullfile(cas.dir.ansys_in, "case-files"), fullfile(cas.dir.ansys_in, "geometry"), fullfile(cas.dir.ansys_in, "journals")};
    
    % Create directories if not present
    for i = 1:length(dirsToCreate)
        createDirIfNotExists(dirsToCreate{i});
    end
end

function cas = organize_DICOMS(cas)
% ORGANIZE_FLOW_ANATOMY
% - Lists DICOMs
% - Picks/organizes anatomy (T2) into patient-data/<cas.subj>/anatomy/<series_desc>
% - Organizes flow series into patient-data/<cas.subj>/flow/zK-<level>/01PC/<series_desc>_{00,MAG_01,P_02}

    %% Setup
    
    % List DICOM series
    T = list_dicom_series(cas.dir.patient);
    cas.model = T.Manufacturer{1};

    % Find an existing subfolder inside 'anatomy' (if any)
    existing = dir(cas.dir.anatomy);
    existing = existing([existing.isdir] & ~ismember({existing.name},{'.','..'}));
    
    fprintf('- Segmentation data .... \n\n');
    
    useExisting = false;
    if ~isempty(existing)
        existing_path = fullfile(cas.dir.anatomy, existing(1).name);
        fprintf('\tExisting content in "anatomy": %s \n\t', existing(1).name);
        if askYN('Do you want to use it? ([y]/n): ')
            % Keep existing anatomy; skip T2 selection
            useExisting = true;
        else
            rmdir(existing_path, 's');
        end
    end
    
    % Select T2 series to construct segmentation only if replacing or none exists
    if ~useExisting
        % pass 'true' to skip internal "existing anatomy" prompt inside picker
        pick_T2_series(cas, T, true);
        % copyfile(anatomy_dicom, dest_folder);
    end
    
    fprintf('\n- Velocity data .... \n');
        
    % Show existing content (if any)
    items = dir(cas.dir.flow);
    items = items([items.isdir]);
    items = items(~ismember({items.name},{'.','..'}));
    if ~isempty(items)
        fprintf('\n\tExisting content in "flow": ');
        for k = 1:numel(items)
            fprintf(' %s |', items(k).name);
        end
            fprintf('\n\t');
        if ~askYN('Do you want to use it? ([y]/n): ')
            rmdir(cas.dir.flow, 's');
            delete_folder_contents(cas.dir.flow);  % wipe but keep root folder
            fprintf('\n\tExisting flow content removed.\n');
        else
            gotoSkipFlow = true; 
        end
    end
    % If we didn't choose to skip, allow selecting multiple "flow/PC" series.
    if ~exist('gotoSkipFlow','var')
        % Filter to "flow" or "PC"
        flowMask = ~cellfun(@isempty, regexpi(T.SeriesDescription, '(flow|PC)', 'once'));
        TF = T(flowMask, :);
    
        if isempty(TF)
            warning('No DICOM series with "flow" or "PC" found under: %s', cas.dir.patient);
        else
            % Build menu
            choices = strings(height(TF),1);
            paths   = strings(height(TF),1);
            for i = 1:height(TF)
                choices(i) = sprintf('%2d) %s / %s / %s : Ser%03d  %s', ...
                    i, TF.PAT{i}, TF.ST{i}, TF.SE{i}, TF.SeriesNumber(i), TF.SeriesDescription{i});
                pth = fullfile(cas.dir.patient, TF.PAT{i}, TF.ST{i}, TF.SE{i});
                if ~isfolder(pth)
                    pth = fullfile(cas.dir.patient, TF.ST{i}, TF.SE{i});
                    if ~isfolder(pth)
                        pth = fullfile(cas.dir.patient, TF.SE{i});
                    end
                end
                paths(i) = pth;
            end
    
            % Interactive loop: z0, z1, ...
            z = 0;
            while true
                fprintf('\n\tFlow/PC series found:\n\n');
                for i = 1:numel(choices)
                    fprintf('\t\t%s\n', choices(i));
                end
                fprintf ("\n\tOrdered from cranial to caudal direction (e.g., FM-15 first, FM-5 second, C1-C2 third, C3-C3, fourth)... \n")
                sel = askIndexOrQuit(sprintf('\t... pick flow series [1..%d] (q to quit): ', numel(choices)), numel(choices));
                if sel == 0
                    break;
                end
    
                src_path   = char(paths(sel));

                series_desc = sanitize_series_desc(TF.SeriesDescription{sel});

                % decide label based on series description
                sstt = detect_level(TF.SeriesDescription{sel});
    
                % flow/zK-label/01PC/<series_desc>
                z_folder   = fullfile(cas.dir.flow, sprintf('z%d-%s', z, sstt));
                dest_path  = fullfile(z_folder, '01PC', series_desc);
    
                % Base container: flow/zK-<sstt>/01PC/
                base_container = fullfile(z_folder, '01PC');
                createDirIfNotExists(base_container);
                
                % Organize into description_00, description_MAG_01, description_P_02
                split_flow_series(src_path, base_container, series_desc);
                
                z = z + 1;  % next slice level
            end
        end
    end

end


%% Auxiliary functions 


function T = list_dicom_series(rootDir, csvOut)
% LIST_DICOM_SERIES  List DICOM series under rootDir (handles 2 layouts).
%
%   T = list_dicom_series(rootDir)
%   T = list_dicom_series(rootDir, 'series_list.csv')
%
% Handles:
%   (A) Siemens tree: .../PATxxxx/STxxxxxx/SE000001/MR000123
%   (B) Flat dump:    .../IMAGES/IM000001 (or similar) with multiple series mixed
%
% Output columns:
%   PAT, ST, SE, Manufacturer, StudyDate, StudyTime, SeriesNumber, SeriesDescription, SeriesInstanceUID
%
% Notes:
%   - In flat layout, PAT/ST may be unknown; left blank.
%   - Series are grouped by SeriesInstanceUID (one row per UID).

    if nargin < 1 || ~isfolder(rootDir)
        error('Folder not found: %s', string(rootDir));
    end
    if nargin < 2, csvOut = ''; end

    % ------------------------------------------------------------
    % Detect layout: do we have SE* folders anywhere under rootDir?
    % ------------------------------------------------------------
    seDirs = dir(fullfile(rootDir, '**', 'SE*'));
    seDirs = seDirs([seDirs.isdir]);
    useSEFolders = ~isempty(seDirs);

    % Data accumulator
    data = struct('PAT', {}, 'ST', {}, 'SE', {}, 'Manufacturer', {}, ...
                  'StudyDate', {}, 'StudyTime', {}, 'SeriesNumber', {}, ...
                  'SeriesDescription', {}, 'SeriesInstanceUID', {});

    if useSEFolders
        % ============================================================
        % Case A: Siemens layout (SE folders exist) => fast per SE folder
        % ============================================================
        for k = 1:numel(seDirs)
            thisSE = fullfile(seDirs(k).folder, seDirs(k).name);

            % Look for one MR* file inside this SE folder
            mr = dir(fullfile(thisSE, 'MR*'));
            mr = mr(~[mr.isdir]);

            if isempty(mr)
                % sometimes files are nested deeper; handle it
                mr = dir(fullfile(thisSE, '**', 'MR*'));
                mr = mr(~[mr.isdir]);
            end

            if isempty(mr)
                % no dicoms here
                continue
            end

            sampleFile = fullfile(mr(1).folder, mr(1).name);
            info = safe_dicominfo(sampleFile);
            if isempty(info), continue; end

            % SE name is the folder itself (e.g., SE000001)
            SEname = string(seDirs(k).name);

            data = append_series_row(data, info, thisSE, SEname);
        end

    else
        % ============================================================
        % Case B: Flat dump (e.g., IMAGES) => scan + group by Series UID
        % ============================================================
        dicomFiles = find_dicom_files(rootDir);

        seen = containers.Map('KeyType','char','ValueType','logical');

        for i = 1:numel(dicomFiles)
            sampleFile = dicomFiles{i};
            info = safe_dicominfo(sampleFile);
            if isempty(info), continue; end

            uid = getfield_try(info, 'SeriesInstanceUID', '');
            if isempty(uid)
                % fallback key if UID missing (rare)
                uid = sprintf('SER%d_%s', ...
                    getfield_try(info,'SeriesNumber',0), ...
                    getfield_try(info,'SeriesDescription',''));
            end
            key = char(uid);

            if isKey(seen, key)
                continue; % already captured this series
            end
            seen(key) = true;

            % Use the parent folder name as SE label (often "IMAGES")
            parentFolder = string(string(fileparts(sampleFile)));
            [~, folderName] = fileparts(parentFolder);
            if strlength(folderName) == 0
                folderName = "IMAGES";
            end

            % We pass "thisSE" as the folder path; PAT/ST likely unknown here
            thisSE = fileparts(sampleFile);
            data = append_series_row(data, info, thisSE, folderName);
        end
    end

    % ------------------------------------------------------------
    % Build table, sort, print
    % ------------------------------------------------------------
    if isempty(data)
        T = table();
        fprintf('\tNo series found under %s\n', rootDir);
        return
    end

    T = struct2table(data);

    % Sort: if PAT/ST empty (flat layout), sort by StudyDate/SeriesNumber
    if all(cellfun(@isempty, T.PAT)) && all(cellfun(@isempty, T.ST))
        T = sortrows(T, {'StudyDate','StudyTime','SeriesNumber'});
    else
        T = sortrows(T, {'PAT','ST','SeriesNumber'});
    end

    % Print summary
    lastPAT = '';
    lastST  = '';
    for i = 1:height(T)
        pat = T.PAT{i};
        st  = T.ST{i};

        if isempty(pat) && isempty(st)
            % Flat layout (no PAT/ST)
            if i == 1
                fprintf('\n\t%s\n', rootDir);
            end
        else
            if ~strcmp(lastPAT, pat) || ~strcmp(lastST, st)
                fprintf('\n\t%s / %s\n', pat, st);
                lastPAT = pat; lastST = st;
            end
        end

        fprintf('\t\t%s : Ser%03d %s\n', T.SE{i}, T.SeriesNumber(i), T.SeriesDescription{i});
    end
    fprintf('\n\tTotal series: %d\n\n', height(T));

    % Optional CSV
    if ~isempty(csvOut)
        writetable(T, csvOut);
        fprintf('Wrote %s\n', csvOut);
    end
end

% ======================================================================
% Helpers
% ======================================================================

function info = safe_dicominfo(f)
    try
        info = dicominfo(f);
    catch
        info = [];
    end
end

function files = find_dicom_files(rootDir)
    % Try common filename patterns first (fast-ish), then fallback to all files.
    pats = {'MR*','IM*','*.dcm','*.DCM'};
    files = {};
    for p = 1:numel(pats)
        d = dir(fullfile(rootDir, '**', pats{p}));
        d = d(~[d.isdir]);
        for k = 1:numel(d)
            files{end+1} = fullfile(d(k).folder, d(k).name); %#ok<AGROW>
        end
    end

    % If nothing found, fall back to "all files" and let dicominfo reject non-DICOMs
    if isempty(files)
        d = dir(fullfile(rootDir, '**', '*'));
        d = d(~[d.isdir]);
        for k = 1:numel(d)
            files{end+1} = fullfile(d(k).folder, d(k).name); %#ok<AGROW>
        end
    end
end

function data = append_series_row(data, info, thisSE, SEname)
    % Pull fields with safe fallbacks
    StudyDate  = getfield_try(info, 'StudyDate', '00000000');
    StudyTime  = sanitize_time(getfield_try(info, 'StudyTime', '000000'));
    SeriesNum  = getfield_try(info, 'SeriesNumber', 0);
    SeriesDesc = getfield_try(info, 'SeriesDescription', '');
    if isempty(SeriesDesc)
        SeriesDesc = getfield_try(info, 'ProtocolName', '');
    end

    Manufacturer = upper(strtrim(getfield_try(info, 'Manufacturer', '')));
    if contains(Manufacturer, 'SIEMENS')
        Manufacturer = 'SIEMENS';
    elseif contains(Manufacturer, 'GE')
        Manufacturer = 'GE';
    elseif isempty(Manufacturer)
        Manufacturer = '';
    else
        % Keep as-is, don’t error out (some vendors put unexpected strings)
        Manufacturer = char(string(Manufacturer));
    end

    SeriesUID = getfield_try(info, 'SeriesInstanceUID', '');

    % Extract PAT/ST from path if it looks like .../PATxxx/STxxx/SE...
    parts = split(string(thisSE), filesep);
    PAT = ""; ST = "";
    if numel(parts) >= 3
        PATcand = parts(end-2);
        STcand  = parts(end-1);
        if startsWith(PATcand, "PAT") && startsWith(STcand, "ST")
            PAT = PATcand;
            ST  = STcand;
        end
    end

    data(end+1) = struct( ...
        'PAT', char(PAT), ...
        'ST',  char(ST), ...
        'SE',  char(string(SEname)), ...
        'Manufacturer',  char(Manufacturer), ...
        'StudyDate',  char(StudyDate), ...
        'StudyTime',  char(StudyTime), ...
        'SeriesNumber', double(SeriesNum), ...
        'SeriesDescription', char(SeriesDesc), ...
        'SeriesInstanceUID', char(string(SeriesUID)) );
end

function val = getfield_try(s, field, defaultVal)
    % Safe getter for struct fields; returns defaultVal if missing/empty.
    if isstruct(s) && isfield(s, field)
        val = s.(field);
        if isempty(val)
            val = defaultVal;
        end
    else
        val = defaultVal;
    end
end

function t = sanitize_time(tin)
    % Make StudyTime printable and consistent (HHMMSS or HHMMSS.FFFFFF).
    % dicominfo can return char or numeric.
    if isnumeric(tin)
        t = num2str(tin);
    else
        t = char(tin);
    end
    t = strtrim(t);
    if isempty(t)
        t = '000000';
        return
    end

    % Remove any colons
    t = strrep(t, ':', '');

    % Pad if too short
    if numel(t) < 6
        t = [t repmat('0', 1, 6-numel(t))];
    end
end

% % ---- helpers ----
% function v = getfield_try(s, fld, defaultVal)
%     if isfield(s, fld) && ~isempty(s.(fld))
%         v = s.(fld);
%     else
%         v = defaultVal;
%     end
% end
% 
% function t = sanitize_time(tin)
%     t = char(string(tin));
%     t = regexprep(t, '\D', '');
%     if isempty(t), t = '000000'; end
%     if numel(t) >= 6, t = t(1:6); else, t = pad(t, 6, 'right', '0'); end
% end
function [anatomy_dicom, dest_folder, series_desc, idx, T2T] = pick_T2_series(cas, T, skipExistingCheck)
% PICK_T2_SERIES
% - Lists DICOM series and filters to T2
% - Lets user choose one
% - If anatomy/<series_desc> already exists, ask to replace it (unless skipped)
% - IMPORTANT: even if multiple series live in the same folder, it copies ONLY the
%   selected series (by SeriesInstanceUID) into dest_folder and returns that folder.
%
% Outputs
%   anatomy_dicom : destination folder containing ONLY the chosen series DICOMs
%   dest_folder   : same as anatomy_dicom
%   series_desc   : sanitized series description for folder naming
%   idx           : selected row index within T2T
%   T2T           : filtered table of T2 series

    if nargin < 3 || isempty(skipExistingCheck)
        skipExistingCheck = false;
    end

    % --- list & filter T2 ---
    isT2 = ~cellfun(@isempty, regexpi(T.SeriesDescription, 'T2', 'once'));
    T2T  = T(isT2, :);
    if isempty(T2T)
        error('No series with "T2" found under: %s', cas.dir.patient);
    end

    % --- build choices and paths ---
    choices = strings(height(T2T),1);
    paths   = strings(height(T2T),1);

    for i = 1:height(T2T)
        choices(i) = sprintf('%s / %s / %s : Ser%03d  %s', ...
            T2T.PAT{i}, T2T.ST{i}, T2T.SE{i}, T2T.SeriesNumber(i), T2T.SeriesDescription{i});

        pth = fullfile(cas.dir.patient, T2T.PAT{i}, T2T.ST{i}, T2T.SE{i})
        if ~isfolder(pth)
            pth = fullfile(cas.dir.patient, T2T.ST{i}, T2T.SE{i})
            if ~isfolder(pth)
                pth = fullfile(cas.dir.patient, T2T.SE{i})
            end
        end
        if ~isfolder(pth)
            error('Series folder not found for row %d. Tried: %s', i, pth);
        end
        paths(i) = pth;
    end

    % --- user picks series ---
    if height(T2T) > 1
        fprintf('\nT2 series found:\n\n');
        for i = 1:numel(choices)
            fprintf('\t%2d) %s\n', i, choices(i));
        end
        fprintf('\n');
        idx = askInt('Enter the number of the series to use for anatomy: ', 1, numel(choices));
    else
        idx = 1;
        fprintf('\nOnly one T2 series found. Using:\n   %s\n', choices(1));
    end

    % --- destination folder name ---
    series_desc = regexprep(T2T.SeriesDescription{idx}, '[^\w\-]', '_');
    dest_folder = fullfile(cas.dir.anatomy, series_desc);

    % --- optionally ask about replacing existing anatomy folder ---
    if ~skipExistingCheck && isfolder(dest_folder)
        resp = askYN(sprintf('- Anatomy folder "%s" already exists. Replace it? (y/n): ', series_desc));
        if resp
            rmdir(dest_folder, 's');
        else
            error('- Aborted: user chose not to replace existing anatomy folder.');
        end
    end

    % --- find files belonging ONLY to the chosen series ---
    srcFolder = string(paths(idx));

    % Prefer SeriesInstanceUID if available
    targetUID = "";
    if any(strcmpi(T2T.Properties.VariableNames, 'SeriesInstanceUID'))
        targetUID = string(T2T.SeriesInstanceUID{idx});
    end

    if strlength(targetUID) > 0
        files = list_dicom_files_for_uid(srcFolder, targetUID);
    else
        % Fallback: SeriesNumber (less robust)
        warning('SeriesInstanceUID not found in table T; falling back to SeriesNumber filtering.');
        targetSeriesNumber = T2T.SeriesNumber(idx);
        files = list_dicom_files_for_seriesnumber(srcFolder, targetSeriesNumber);
    end

    % --- copy only those files into dest_folder ---
    if ~isfolder(dest_folder), mkdir(dest_folder); end
    for k = 1:numel(files)
        copyfile(files{k}, dest_folder);
    end

    anatomy_dicom = dest_folder; % return the folder that contains only the chosen series
end


% ========================= Helpers =========================

function files = list_dicom_files_for_uid(folder, targetUID)
    D = dir(folder);
    D = D(~[D.isdir]);

    files = {};
    for i = 1:numel(D)
        f = fullfile(D(i).folder, D(i).name);
        try
            info = dicominfo(f);
            if isfield(info,'SeriesInstanceUID') && string(info.SeriesInstanceUID) == string(targetUID)
                files{end+1} = f; %#ok<AGROW>
            end
        catch
            % ignore non-DICOM / unreadable files
        end
    end

    if isempty(files)
        error('No DICOM files matched SeriesInstanceUID %s in folder %s', targetUID, folder);
    end
end

function files = list_dicom_files_for_seriesnumber(folder, targetSeriesNumber)
    D = dir(folder);
    D = D(~[D.isdir]);

    files = {};
    for i = 1:numel(D)
        f = fullfile(D(i).folder, D(i).name);
        try
            info = dicominfo(f);
            if isfield(info,'SeriesNumber') && double(info.SeriesNumber) == double(targetSeriesNumber)
                files{end+1} = f; %#ok<AGROW>
            end
        catch
            % ignore non-DICOM / unreadable files
        end
    end

    if isempty(files)
        error('No DICOM files matched SeriesNumber %g in folder %s', targetSeriesNumber, folder);
    end
end

function v = askInt(prompt, lo, hi)
    v = input(prompt);
    while ~(isscalar(v) && isnumeric(v) && isfinite(v) && v==floor(v) && v>=lo && v<=hi)
        v = input(sprintf('Enter an integer in [%d, %d]: ', lo, hi));
    end
end

function ok = askYN(prompt)
    resp = input(prompt,'s');
    resp = strtrim(lower(resp));
    if isempty(resp)          % Enter defaults to YES
        ok = true; return;
    end
    while ~ismember(resp, {'y','n'})
        resp = input('Please answer y or n (Enter = y): ','s');
        resp = strtrim(lower(resp));
        if isempty(resp)
            ok = true; return;
        end
    end
    ok = strcmp(resp,'y');
end

function sel = askIndexOrQuit(prompt, hi)
% Returns 0 if user enters 'q' (quit). Otherwise an integer in [1..hi].
    while true
        resp = strtrim(lower(input(prompt,'s')));
        if strcmp(resp,'q')
            sel = 0; return;
        end
        val = str2double(resp);
        if ~isnan(val) && isfinite(val) && val==floor(val) && val>=1 && val<=hi
            sel = val; return;
        end
        fprintf('Invalid input. Enter an integer in [1..%d] or q to quit.\n', hi);
    end
end

function name = sanitize_series_desc(s)
% Safe folder name derived from SeriesDescription/ProtocolName
    if isempty(s), s = 'Series'; end
    name = regexprep(s, '[^\w\-]', '_');         % keep word chars and hyphen
    name = regexprep(name, '_+', '_');           % collapse repeats
    name = regexprep(name, '^_+|_+$', '');       % trim underscores
    if isempty(name), name = 'Series'; end
end

function sstt = detect_level(desc)
% Detect anatomical level keyword from SeriesDescription (case-insensitive)
    d = lower(desc);
    d = sanitize_series_desc(d);

    if contains(d,'foramen') || contains(d,'foreman') || contains(d,'magnum') || contains(d,'fm')
        if contains(d,'_5')
            sstt = 'FM-5';
        elseif contains(d,'_10')
            sstt = 'FM-10';
        elseif contains(d,'_15')
            sstt = 'FM-15';
        else
            sstt = 'FM';
        end

    elseif contains(d,'c1') && contains(d,'c2')
        sstt = 'C1C2';
    elseif contains(d,'c2') && contains(d,'c3')
        sstt = 'C2C3';
    elseif contains(d,'c3') && contains(d,'c4')
        sstt = 'C3C4';
    elseif contains(d,'c4') && contains(d,'c5')
        sstt = 'C4C5';
    elseif contains(d,'c5') && contains(d,'c6')
        sstt = 'C5C6';
    else
        sstt = 'UNK';  % unknown
    end
end

function split_flow_series(src_path, dest_base, base_name)
% SPLIT_FLOW_SERIES
% Copies ONLY the DICOMs in src_path that belong to the flow series whose
% SeriesDescription matches base_name (case-insensitive).
%
% Creates:
%   <dest_base>/<base_name>_00
%   <dest_base>/<base_name>_MAG_01
%   <dest_base>/<base_name>_P_02
%
% And copies:
%   - MR000000..MR000029  -> _00 and _P_02
%   - MR000030..MR000059  -> _MAG_01
%
% src_path can have nested subfolders.
%
% NOTE: This function does NOT copy everything in src_path anymore.
%       It filters by DICOM SeriesDescription (and locks SeriesInstanceUID).

    if nargin < 3 || isempty(base_name)
        error('base_name is required.');
    end
    if ~isfolder(src_path)
        error('src_path is not a folder: %s', src_path);
    end

    % Keep an unsanitized version for matching against DICOM header
    base_name_match = string(base_name);

    % Sanitize base_name for filesystem safety (folder names)
    base_name_fs = regexprep(base_name, '[^\w\-]', '_');
    base_name_fs = regexprep(base_name_fs, '_+', '_');
    base_name_fs = regexprep(base_name_fs, '^_+|_+$', '');
    if isempty(base_name_fs), base_name_fs = 'Series'; end

    dest00   = fullfile(dest_base, [base_name_fs '_00']);
    destMAG  = fullfile(dest_base, [base_name_fs '_MAG_01']);
    destP02  = fullfile(dest_base, [base_name_fs '_P_02']);

    createDirIfNotExists(dest_base);
    createDirIfNotExists(dest00);
    createDirIfNotExists(destMAG);
    createDirIfNotExists(destP02);

    % ---- collect all files under src_path (DICOMs may have no extension) ----
    allFiles = dir(fullfile(src_path, '**', '*'));
    allFiles = allFiles(~[allFiles.isdir]);

    % Helper: parse MR/IM index e.g., MR000030 or IM000030
    mr_im_index = @(fname) local_mr_im_index(fname);

    % ---- first pass: find candidate files that match SeriesDescription ----
    matchFiles = {};
    matchUIDs  = strings(0);

    for k = 1:numel(allFiles)
        f = fullfile(allFiles(k).folder, allFiles(k).name);

        % Quick filter: only consider files that look like MR######
        idx = mr_im_index(allFiles(k).name);
        if isnan(idx)
            continue;
        end

        try
            info = safe_dicominfo(f);
        catch
            continue; % not readable DICOM
        end


        if isfield(info, 'SeriesDescription')
            sd = string(info.SeriesDescription);
        else
            sd = "";
        end

        if contains(lower(sanitize_series_desc(sd)), lower(base_name_match))
            matchFiles{end+1} = f; %#ok<AGROW>
            if isfield(info,'SeriesInstanceUID')
                matchUIDs(end+1) = string(info.SeriesInstanceUID); %#ok<AGROW>
            else
                matchUIDs(end+1) = ""; %#ok<AGROW>
            end
        end
    end

    if isempty(matchFiles)
        error('No DICOMs matched SeriesDescription containing "%s" under: %s', base_name_match, src_path);
    end

    % ---- lock to ONE SeriesInstanceUID (extra safety if multiple matches) ----
    % If UID is missing, we skip the lock and just use SeriesDescription match.
    nonEmptyUIDs = matchUIDs(matchUIDs ~= "");
    lockUID = "";
    if ~isempty(nonEmptyUIDs)
        % pick the most frequent UID among matches
        [u,~,ic] = unique(nonEmptyUIDs);
        counts = accumarray(ic, 1);
        [~,imax] = max(counts);
        lockUID = u(imax);
    end

    % ---- copy only matching files (and matching UID if available) ----
    n00 = 0; nP = 0; nMAG = 0;
% --- build list of (file, idx) first ---
fileList = {};
idxList  = [];

    for k = 1:numel(matchFiles)
        srcFile = matchFiles{k};
        [~, nm, ext] = fileparts(srcFile);
        idx = mr_im_index([nm ext]);
        if isnan(idx), continue; end
    
        % enforce UID lock if available
        if strlength(lockUID) > 0
            try
                info = dicominfo(srcFile);
                if ~isfield(info,'SeriesInstanceUID') || string(info.SeriesInstanceUID) ~= lockUID
                    continue;
                end
            catch
                continue;
            end
        end
    
        fileList{end+1} = srcFile; %#ok<AGROW>
        idxList(end+1)  = idx;     %#ok<AGROW>
    end
    
    if numel(fileList) ~= 60
        error('Expected 60 MR/IM files for the series; found %d.', numel(fileList));
    end
    
    % --- sort by idx and split first 30 / next 30 ---
    [~, ord] = sort(idxList, 'ascend');
    first30 = ord(1:30);
    next30  = ord(31:60);
    
    % --- copy first 30 to dest00 and destP02; next 30 to destMAG ---
    for ii = first30
        srcFile = fileList{ii};
        [~, nm, ext] = fileparts(srcFile);
    
        copyfile(srcFile, fullfile(dest00,  [nm ext]));  n00 = n00 + 1;
        copyfile(srcFile, fullfile(destP02, [nm ext]));  nP  = nP  + 1;
    end
    
    for ii = next30
        srcFile = fileList{ii};
        [~, nm, ext] = fileparts(srcFile);
    
        copyfile(srcFile, fullfile(destMAG, [nm ext]));  nMAG = nMAG + 1;
    end

    fprintf('\n\tFiltered copy done (SeriesDescription contains "%s"):\n', base_name_match);
    if strlength(lockUID) > 0
        fprintf('\tLocked to SeriesInstanceUID: %s\n', lockUID);
    end
    fprintf('\t_00:     %d files\n', n00);
    fprintf('\t_P_02:   %d files\n', nP);
    fprintf('\t_MAG_01: %d files\n', nMAG);

    if n00 == 0 && nP == 0 && nMAG == 0
        error('Matched series, but no MR000000..MR000059 files were copied. Check naming / ranges.');
    end
end


function n = local_mr_im_index(fname)
    % Accepts MR#### or IM#### (with or without extension)
    [~, just] = fileparts(fname);
    tok = regexp(just, '^(MR|IM)(\d+)$', 'tokens', 'once');
    if isempty(tok)
        n = NaN;
    else
        n = str2double(tok{2});
    end
end

function createDirIfNotExists(p)
    if ~isfolder(p), mkdir(p); end
end

function [cas, dat_PC] = main_1_read_dat(cas)

    % Auxiliary directories to clean or create
    out_folder = fullfile(tempdir, 'pc-MRI');

    cas = scan_folders_set_cas(cas, out_folder);

    if cas.Ncas > 0
        dat_PC = read_dicoms_PC(cas);
    else
        error("No PC DICOMS found!" + newline)
    end
    
    % Get all directories starting with 'aux' in out_folder
    d = dir(fullfile(out_folder, 'aux*'));
    for k = 1:numel(d)
        if d(k).isdir
            rmdir(fullfile(out_folder, d(k).name), 's'); % 's' removes contents recursively
        end
    end

end

function cas = scan_folders_set_cas(cas, out_folder)

    get_folders = fullfile(cas.dir.git, 'matlab','functions','others','get_folders.sh');
   
    for measurement = "PC" % ["PC", "RT", "FM"]
        createOrCleanDir(fullfile(out_folder, "aux_" + measurement));
        system(sprintf('bash %s "%s" "%s" "%s"', get_folders, cas.dir.flow, out_folder, measurement));
        if dir(fullfile(out_folder, "aux_" + measurement, "folders.txt")).bytes > 0
            % File exists and is not empty — break or return
            break
        end
    end
    
    strfolders_PC = fileread(fullfile(out_folder,'aux_PC', 'folders.txt'));
    folders_PC = regexp(strfolders_PC, '\r\n|\r|\n', 'split');
    folders_PC(end) = [];
    
    strfolders_PC_ = fileread(fullfile(out_folder,'aux_PC', 'folders_.txt'));
    folders_PC_ = regexp(strfolders_PC_, '\r\n|\r|\n', 'split');
    folders_PC_(end) = [];
    
    strfolders_PC_P = fileread(fullfile(out_folder, 'aux_PC', 'folders_P.txt'));
    folders_PC_P = regexp(strfolders_PC_P, '\r\n|\r|\n', 'split');
    folders_PC_P(end) = [];
    
    strfolders_PC_MAG = fileread(fullfile(out_folder, 'aux_PC', 'folders_MAG.txt'));
    folders_PC_MAG = regexp(strfolders_PC_MAG, '\r\n|\r|\n', 'split');
    folders_PC_MAG(end) = [];
    
    Ncas_PC = length(folders_PC);
    
    if Ncas_PC > 0
        for nn = 1:Ncas_PC
            % include only data 
            ind = strfind(folders_PC{nn}, '/')-1;
            ind = ind(1);
            locations_PC{nn} = folders_PC{nn}(4:ind);
            names_PC{nn} = strrep(folders_PC{nn},'/','-');
            zones_PC{nn} = folders_PC{nn}(1:2);
        end
    else
        folders_PC = {};
        folders_PC_ = {};
        folders_PC_P = {};
        folders_PC_MAG = {};
        names_PC = {};
        zones_PC = {};
        locations_PC = {};
    end
    cas.Ncas        = Ncas_PC;
    cas.folders     = folders_PC;
    cas.folders_    = folders_PC_;
    cas.folders_P   = folders_PC_P;
    cas.folders_MAG = folders_PC_MAG;
    cas.names       = names_PC;
    cas.zones       = zones_PC;
    cas.locations   = locations_PC;

end


% Helper function to clean or create a directory
function createOrCleanDir(dirPath)
    if ~isfolder(dirPath)
        mkdir(dirPath);
    else
        delete(fullfile(dirPath, '*'));
    end
end

function delete_folder_contents(rootPath)
% Remove all files and subfolders inside rootPath, keep root
    if ~isfolder(rootPath), return; end
    listing = dir(rootPath);
    keep = ~ismember({listing.name},{'.','..'});
    listing = listing(keep);
    for k = 1:numel(listing)
        p = fullfile(listing(k).folder, listing(k).name);
        if listing(k).isdir
            rmdir(p, 's');
        else
            delete(p);
        end
    end
end

function dat = read_dicoms_PC(cas)

    Ndat = length(cas.folders_);

    % Initial guess (can be refined after reading first header)
    if strcmp(cas.model, 'GE')
        dicom_ext = {'IM*','MR*','*'};
    elseif strcmp(cas.model, 'SIEMENS')
        dicom_ext = {'*.dcm','*.ima','*'};   % safe default
    else
        dicom_ext = {'*'};
    end

    % Preallocate main outputs
    pixel_coord = cell(1, Ndat);

    % These were used later; keep as cells
    info        = cell(1, Ndat);
    infomag     = cell(1, Ndat);
    infocom     = cell(1, Ndat);

    im_unsorted    = cell(1, Ndat);
    immag_unsorted = cell(1, Ndat);
    imcom_unsorted = cell(1, Ndat);

    venc      = cell(1, Ndat);   
    vencscale = cell(1, Ndat);   
    triggertime = cell(1, Ndat);
    location    = cell(1, Ndat);
    fcal_V_cm_px = cell(1, Ndat);
    fcal_H_cm_px = cell(1, Ndat);

    im     = cell(1, Ndat);
    immag  = cell(1, Ndat);
    imcom  = cell(1, Ndat);

    phase  = cell(1, Ndat);
    magni  = cell(1, Ndat);
    compl  = cell(1, Ndat);

    U_tot  = cell(1, Ndat);
    Vscale = cell(1, Ndat);

    t      = cell(1, Ndat);
    Nt     = cell(1, Ndat);
    dt     = cell(1, Ndat);
    T      = cell(1, Ndat);
    locz   = cell(1, Ndat);
    onepxarea = cell(1, Ndat);

    fname_showorient = cell(1, Ndat);

    for idat = 1:Ndat

        % ---------- Load PC/phase directory ----------
        dicomlist = list_files_multi_pattern(fullfile(cas.dir.flow, cas.folders_P{idat}), dicom_ext);
        numim = numel(dicomlist);

        if numim == 0
            error('No files found in %s for patterns: %s', ...
                fullfile(cas.dir.flow, cas.folders_P{idat}), strjoin(string(dicom_ext), ', '));
        end
        venc_suggested = 10;

        % Collect headers and images
        for jj = 1:numim

            fname = fullfile(dicomlist(jj).folder, dicomlist(jj).name);
            info{idat}{jj} = dicominfo(fname);

            if jj == 1
                % Identify manufacturer ONCE from the first DICOM we successfully read
                if idat == 1 
                    if isfield(info{idat}{jj}, 'Manufacturer') && contains(upper(info{idat}{jj}.Manufacturer), 'SIEMENS')
                        cas.model = 'SIEMENS';
                        dicom_ext = {'*.dcm','*.ima','*'};
                    elseif isfield(info{idat}{jj}, 'Manufacturer') && contains(upper(info{idat}{jj}.Manufacturer), 'GE')
                        cas.model = 'GE';
                        dicom_ext = {'IM*','MR*','*'};
                    end
                end

                % Hack to find VENC:
                if strcmp(cas.model, 'SIEMENS')
                    command = sprintf('awk ''/^sAngio.sFlowArray.asElm\\[0\\].nVelocity/'' "%s"', fname);
                    [~, sysout] = system(command);
                    sysout = erase(sysout, "sAngio.sFlowArray.asElm[0].nVelocity");
                    sysout = erase(sysout, "=");
                    sysout = sysout(find(~isspace(sysout)));
                    venc{idat} = str2double(sysout);
    
                elseif strcmp(cas.model, 'GE')
    
                    % ---- 1) Try GE private tag (0019,10CC): VelocityEncoding (cm/s) ----
                    venc_val = NaN;
                    tag_venc = dicomlookup('0019','10CC');
                    
                    if isfield(info{idat}{jj}, tag_venc)
                        tmp = double(info{idat}{jj}.(tag_venc));
                        if ~isempty(tmp) && ~isnan(tmp)
                            venc_val = 0.1 * tmp*(tmp>50) + tmp*(tmp<50);   % cm/s
                        end
                    end
                    
                % ---- 2) Fallback: parse SeriesDescription (usually cm/s) ----
                if isnan(venc_val) && isfield(info{idat}{jj}, 'SeriesDescription')
                    desc = string(info{idat}{jj}.SeriesDescription);
                    tok  = regexp(desc, 'VENC\s*([0-9]+(\.[0-9]+)?)', 'tokens', 'once');
                    if ~isempty(tok)
                        venc_suggested = str2double(tok{1});  % cm/s
                    end
                end
                
                % ---- 3) Last resort: ask user ----
                if isnan(venc_val)
                
                    fprintf('\nSeriesDescription: %s\n', info{idat}{1}.SeriesDescription);
                    fprintf('VENC not found in metadata.\n');
                
                    if ~isnan(venc_suggested)
                        fprintf('Suggested VENC from SeriesDescription: %.0f cm/s\n', venc_suggested);
                    end
                
                    while true
                        if ~isnan(venc_suggested)
                            venc_user = input( ...
                                sprintf('Enter VENC [cm/s] (press Enter to use %.0f): ', venc_suggested), ...
                                's');
                        else
                            venc_user = input('Enter VENC [cm/s]: ', 's');
                        end
                
                        % --- handle Enter ---
                        if isempty(venc_user) && ~isnan(venc_suggested)
                            venc_val = venc_suggested;
                            break
                        end
                
                        % --- validate manual input ---
                        venc_user = str2double(venc_user);
                        if isnan(venc_user) || ~isscalar(venc_user) || venc_user <= 0
                            fprintf('Invalid VENC value. Please enter a positive scalar.\n\n');
                        else
                            venc_val = venc_user;
                            break
                        end
                    end
                end
                    
                    % ---- Store ----
                    venc{idat} = venc_val;
    
                    % ---- Velocity scale (GE private tag 0019,10E2) ----
                    vencscale_val = NaN;
                    tag_vencscale = dicomlookup('0019','10E2');
                    
                    % 1) Try GE private tag
                    if isfield(info{idat}{jj}, tag_vencscale)
                        tmp = double(info{idat}{jj}.(tag_vencscale));
                        if ~isempty(tmp) && ~isnan(tmp)
                            vencscale_val = tmp;
                        end
                    end
                    
                    % 2) Last resort: ask user (with default)
                    if isnan(vencscale_val)
                    
                        default_vencscale = 1.718874;   % previously observed GE value
                    
                        fprintf('\nVelocityEncodeScale not found in metadata.\n');
                        fprintf('Default value previously used: %.6f\n', default_vencscale);
                    
                        while true
                            vencscale_user = input( ...
                                sprintf('Enter VelocityEncodeScale (press Enter to use %.6f): ', ...
                                        default_vencscale), ...
                                's');
                    
                            if isempty(vencscale_user)
                                vencscale_val = default_vencscale;
                                break
                            end
                    
                            vencscale_user = str2double(vencscale_user);
                            if isnan(vencscale_user) || vencscale_user <= 0
                                fprintf('Invalid value. Please enter a positive scalar.\n\n');
                            else
                                vencscale_val = vencscale_user;
                                break
                            end
                        end
                    end
                    
                    % ---- Store ----
                    vencscale{idat} = vencscale_val;
                end
            end

            if isfield(info{idat}{jj}, 'TriggerTime')
                triggertime{idat}(jj) = double(info{idat}{jj}.(dicomlookup('0018','1060')));
            else
                disp("No TriggerTime dicom field, using 0.0!")
                triggertime{idat}(jj) = 0.0;
            end

            location{idat}(jj) = double(info{idat}{jj}.(dicomlookup('0020','1041'))) / 10.0;

            pixspacing = double(info{idat}{jj}.(dicomlookup('0028','0030')));
            fcal_V_cm_px{idat}(jj) = pixspacing(1) / 10.0;
            fcal_H_cm_px{idat}(jj) = pixspacing(2) / 10.0;

            im_unsorted{idat}{jj} = double(dicomread(info{idat}{jj}));

        end

        % ---------- Load magnitude directory (if exists) ----------
        if isempty(cas.folders_MAG)

            display("Magnitude images do not exist.")
            for jj = 1:numim
                immag_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
            end

        else

            dicomlist_mag = list_files_multi_pattern(fullfile(cas.dir.flow, cas.folders_MAG{idat}), dicom_ext);
            numim_mag = numel(dicomlist_mag);

            if numim_mag == 0
                warning('No magnitude files found in %s', fullfile(cas.dir.flow, cas.folders_MAG{idat}));
                for jj = 1:numim
                    immag_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
                end
            else
                fname_showorient{idat} = fullfile(dicomlist_mag(1).folder, dicomlist_mag(1).name);

                for jj = 1:numim_mag
                    fname = fullfile(dicomlist_mag(jj).folder, dicomlist_mag(jj).name);
                    infomag{idat}{jj} = dicominfo(fname);
                    immag_unsorted{idat}{jj} = double(dicomread(infomag{idat}{jj}));
                end

                % If magnitude count differs from phase count, we’ll still sort by trigger time of phase;
                % simplest assumption: same ordering/count (common in PC-MRI exports).
                % If yours differs, tell me and we’ll align by InstanceNumber / AcquisitionTime.
            end
        end

        % ---------- Load “complementary” directory ----------
        dicomlist_com = list_files_multi_pattern(fullfile(cas.dir.flow, cas.folders_{idat}), dicom_ext);
        numim_com = numel(dicomlist_com);

        if numim_com == 0
            warning('No complementary files found in %s', fullfile(cas.dir.flow, cas.folders_{idat}));
            for jj = 1:numim
                imcom_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
            end
        else
            for jj = 1:numim_com
                fname = fullfile(dicomlist_com(jj).folder, dicomlist_com(jj).name);
                infocom{idat}{jj} = dicominfo(fname);
                imcom_unsorted{idat}{jj} = double(dicomread(infocom{idat}{jj}));
            end
        end

        % ---------- Sort images by trigger time ----------
        [~, sortind] = sortrows(triggertime{idat}(:), 1);

        triggertime{idat}(:)  = triggertime{idat}(sortind);
        location{idat}(:)     = location{idat}(sortind);
        fcal_V_cm_px{idat}(:) = fcal_V_cm_px{idat}(sortind);
        fcal_H_cm_px{idat}(:) = fcal_H_cm_px{idat}(sortind);

        % Scalars per time series:
        location{idat}    = location{idat}(1);
        fcal_V_cm_px{idat}= fcal_V_cm_px{idat}(1);
        fcal_H_cm_px{idat}= fcal_H_cm_px{idat}(1);
        onepxarea{idat}   = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

        % Reorder images
        for jj = 1:numim
            im{idat}{jj} = im_unsorted{idat}{sortind(jj)};

            % magnitude/complementary might be missing or different length
            if numel(immag_unsorted{idat}) >= jj
                immag{idat}{jj} = immag_unsorted{idat}{sortind(jj)};
            else
                immag{idat}{jj} = zeros(size(im{idat}{jj}));
            end

            if numel(imcom_unsorted{idat}) >= jj
                imcom{idat}{jj} = imcom_unsorted{idat}{sortind(jj)};
            else
                imcom{idat}{jj} = zeros(size(im{idat}{jj}));
            end
        end

        % ---------- Pixel coordinates ----------
        pixel_spacing = info{idat}{1}.PixelSpacing;
        image_position = info{idat}{1}.ImagePositionPatient;
        image_orientation = info{idat}{1}.ImageOrientationPatient;

        row_direction = image_orientation(1:3);
        col_direction = image_orientation(4:6);

        [rows, cols] = size(dicomread(info{idat}{1}));
        pixel_coordinates = zeros(rows, cols, 3);

        for i = 1:rows
            for j = 1:cols
                pixel_coordinates(i, j, :) = image_position ...
                    + (j-1) * row_direction * pixel_spacing(1) ...
                    + (i-1) * col_direction * pixel_spacing(2);
            end
        end
        pixel_coord{idat} = pixel_coordinates;

        % ---------- Build time series + velocity conversion ----------
        for jj = 1:numim
            t{idat}(jj) = double(triggertime{idat}(jj)) / 1000.0;

            phase{idat}(:, :, jj) = im{idat}{jj};
            magni{idat}(:, :, jj) = immag{idat}{jj};
            compl{idat}(:, :, jj) = imcom{idat}{jj};

            if strcmp(cas.model, 'GE')
                Vscale{idat}(jj) = pi * vencscale{idat} / venc{idat};
                U_tot{idat}(:, :, jj) = (phase{idat}(:, :, jj) ./ max(magni{idat}(:, :, jj), 1)) / Vscale{idat}(jj);
            elseif strcmp(cas.model, 'SIEMENS')
                U_tot{idat}(:, :, jj) = -venc{idat} .* ((phase{idat}(:, :, jj) - 2048) ./ 2048);
            end
        end

        % Set first timestamp to zero
        t{idat}(:) = t{idat}(:) - t{idat}(1);

        Nt{idat} = numim;
        dt{idat} = t{idat}(end) / (Nt{idat}-1);
        T{idat}  = t{idat}(end) + dt{idat};

        % If acquisition not equispaced, force uniform phase in [0,1)
        t{idat} = (0:(Nt{idat}-1))/Nt{idat};

        % Slice location relative to first case
        locz{idat} = location{idat} - location{1};

    end

    fprintf('\nList of all cases:\n')
    for idat = 1:Ndat
        disp([num2str(idat, '%02d'), '  -  ', cas.names{idat}])
    end

    % Pack outputs
    dat.pixel_coord  = pixel_coord;
    dat.Ndat         = Ndat;
    dat.locz         = locz;
    dat.Nt           = Nt;
    dat.T            = T;
    dat.t            = t;
    dat.U_tot        = U_tot;
    dat.phase        = phase;
    dat.magni        = magni;
    dat.compl        = compl;
    dat.venc         = venc;
    dat.fcal_H_cm_px = fcal_H_cm_px;
    dat.fcal_V_cm_px = fcal_V_cm_px;
    dat.onepxarea    = onepxarea;
    dat.locations    = cas.locations;

end


% ----------------- Helper: multi-pattern dir() -----------------
function L = list_files_multi_pattern(folderPath, patterns)
    % patterns: char/string OR cell array of char/strings

    if ischar(patterns) || isstring(patterns)
        patterns = {char(patterns)};
    else
        patterns = cellfun(@char, patterns, 'UniformOutput', false);
    end

    L = [];
    for p = 1:numel(patterns)
        tmp = dir(fullfile(folderPath, patterns{p}));
        tmp = tmp(~[tmp.isdir]); % keep files only
        L = [L; tmp]; %#ok<AGROW>
    end

    % Remove duplicates by full path
    if ~isempty(L)
        keys = strcat({L.folder}, filesep, {L.name});
        [~, ia] = unique(keys, 'stable');
        L = L(ia);
    end
end



