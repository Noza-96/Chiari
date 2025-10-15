function cas = organize_DICOMS(cas)
% ORGANIZE_FLOW_ANATOMY
% - Lists DICOMs
% - Picks/organizes anatomy (T2) into patient-data/<cas.subj>/anatomy/<series_desc>
% - Organizes flow series into patient-data/<cas.subj>/flow/zK-<level>/01PC/<series_desc>_{00,MAG_01,P_02}

    %% Setup

    if hasContent(cas.dir.anatomy) && hasContent(cas.dir.flow)
        if askYN('-DICOMs are already organized. Skip? ([y]/n): ')
            return;
        end
    end
    
    % List DICOM series
    T = list_dicom_series(cas.dir.patient);
    cas.model = T.Manufacturer{1};

    % Find an existing subfolder inside 'anatomy' (if any)
    existing = dir(cas.dir.anatomy);
    existing = existing([existing.isdir] & ~ismember({existing.name},{'.','..'}));
    
    fprintf('Segmentation data .... \n\n');
    
    useExisting = false;
    if ~isempty(existing)
        existing_path = fullfile(cas.dir.anatomy, existing(1).name);
        fprintf('Existing content in "anatomy":\n%s\n', existing(1).name);
        if askYN('Do you want to use it? (y/n): ')
            % Keep existing anatomy; skip T2 selection
            useExisting = true;
            fprintf('Keeping existing data; skipping new selection.\n\n');
        else
            rmdir(existing_path, 's');
        end
    end
    
    % Select T2 series to construct segmentation only if replacing or none exists
    if ~useExisting
        % pass 'true' to skip internal "existing anatomy" prompt inside picker
        [anatomy_dicom, dest_folder, series_desc, idx, T2T] = pick_T2_series(cas, T, true);
        copyfile(anatomy_dicom, dest_folder);
    end
    
    fprintf('\nVelocity data .... \n\n');
        
    
    % Show existing content (if any)
    items = dir(cas.dir.flow);
    items = items([items.isdir]);
    items = items(~ismember({items.name},{'.','..'}));
    if ~isempty(items)
        fprintf('Existing content in "flow":\n');
        for k = 1:numel(items)
            fprintf('%s\n', items(k).name);
        end
        if ~askYN('Do you want to use it? (y/n):')
            rmdir(cas.dir.flow, 's');
            % delete_folder_contents(cas.dir.flow);  % wipe but keep root folder
            fprintf('Existing flow content removed.\n');
        else
            fprintf('Keeping existing data; skipping new selection.\n\n');
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
                fprintf('\nFlow/PC series found:\n');
                for i = 1:numel(choices)
                    fprintf('%s\n', choices(i));
                end
                sel = askIndexOrQuit(sprintf('Pick a series [1..%d], or q to stop: ', numel(choices)), numel(choices));
                if sel == 0
                    fprintf('Done selecting velocity series.\n\n');
                    break;
                end
    
                src_path   = char(paths(sel));
                series_desc = sanitize_series_desc(TF.SeriesDescription{sel});
    
                % decide label based on series description
                sstt = detect_level(TF.SeriesDescription{sel});
    
                % flow/zK-label/01PC/<series_desc>
                z_folder   = fullfile(cas.dir.flow, sprintf('z%d-%s', z, sstt));
                dest_path  = fullfile(z_folder, '01PC', series_desc);
                createDirIfNotExists(dest_path);
    
                % Base container: flow/zK-<sstt>/01PC/
                base_container = fullfile(z_folder, '01PC');
                createDirIfNotExists(base_container);
                
                % Organize into description_00, description_MAG_01, description_P_02
                split_flow_series(src_path, base_container, series_desc);
                
                z = z + 1;  % next slice level
            end
        end
        save(fullfile(cas.dir.mat, 'data_0'),"cas");
    end

end


%% Auxiliary functions 


function T = list_dicom_series(rootDir, csvOut)
    % LIST_DICOM_SERIES  Print/return one line per SE0000xx series.
    %   T = list_dicom_series(rootDir)
    %   T = list_dicom_series(rootDir, 'series_list.csv')
    %
    % Output columns: PAT, ST, SE, StudyDate, StudyTime, SeriesNumber, SeriesDescription
    
    if nargin < 1 || ~isfolder(rootDir)
        error('Folder not found: %s', string(rootDir));
    end
    if nargin < 2, csvOut = ''; end
    % Find all SE folders under rootDir (e.g., s3/ST000001/SE000009)
    seDirs = dir(fullfile(rootDir, '**', 'SE*'));
    seDirs = seDirs([seDirs.isdir]);
    
    rows = [];
    data = struct('PAT', {}, 'ST', {}, 'SE', {}, 'Manufacturer', {}, 'StudyDate', {}, 'StudyTime', {}, ...
                  'SeriesNumber', {}, 'SeriesDescription', {});
    
    for k = 1:numel(seDirs)
        thisSE = fullfile(seDirs(k).folder, seDirs(k).name);
        % Look for one MR* file inside this SE folder
        mr = dir(fullfile(thisSE, 'MR*'));
        mr = mr(~[mr.isdir]);
        if isempty(mr)
            % sometimes files are nested one level deeper; handle it
            mr = dir(fullfile(thisSE, '**', 'MR*'));
            mr = mr(~[mr.isdir]);
        end
        if isempty(mr)
            % no dicoms here
            continue
        end
    
        sampleFile = fullfile(mr(1).folder, mr(1).name);
        try
            info = dicominfo(sampleFile);
        catch
            % skip unreadable series
            continue
        end
    
        % Pull fields with safe fallbacks
        StudyDate  = getfield_try(info, 'StudyDate', '00000000');
        StudyTime  = sanitize_time(getfield_try(info, 'StudyTime', '000000'));
        SeriesNum  = getfield_try(info, 'SeriesNumber', 0);
        SeriesDesc = getfield_try(info, 'SeriesDescription', '');
        if isempty(SeriesDesc)
            SeriesDesc = getfield_try(info, 'ProtocolName', '');
        end
        Manufacturer      = upper(strtrim(getfield_try(info, 'Manufacturer', '')));
    
        if contains(Manufacturer, 'SIEMENS')
            Manufacturer = 'SIEMENS';
        elseif contains(Manufacturer, 'GE')
            Manufacturer = 'GE';
        else
            error('Manufacturer "%s" is not known.', Manufacturer);
        end
        % Extract PAT/ST/SE names from the path for convenience
        parts = split(string(thisSE), filesep);
        % Expect .../PATxxxxx/STxxxxxx/SExxxxxx
        PAT = "";
        ST  = "";
        SE  = string(seDirs(k).name);
        if numel(parts) >= 3
            PAT = parts(end-2);
            ST  = parts(end-1);
        end
        data(end+1) = struct( ... 
            'PAT', char(PAT), ...
            'ST',  char(ST), ...
            'SE',  char(SE), ...
            'Manufacturer',  char(Manufacturer), ...
            'StudyDate',  char(StudyDate), ...
            'StudyTime',  char(StudyTime), ...
            'SeriesNumber', double(SeriesNum), ...
            'SeriesDescription', char(SeriesDesc));
    end
    
    % Turn into table and sort by PAT, ST, SeriesNumber
    if isempty(data)
        T = table();
        fprintf('No series found under %s\n', rootDir);
        return
    end
    T = struct2table(data);
    T = sortrows(T, {'PAT','ST','SeriesNumber'});
    lastPAT = '';
    lastST  = '';
    for i = 1:height(T)
        if ~strcmp(lastPAT, T.PAT{i}) || ~strcmp(lastST, T.ST{i})
            fprintf('\n%s / %s\n', T.PAT{i}, T.ST{i});
            lastPAT = T.PAT{i}; lastST = T.ST{i};
        end
        fprintf('%s : Ser%03d %s\n', T.SE{i}, T.SeriesNumber(i), T.SeriesDescription{i});
    end
    fprintf('\nTotal series: %d\n\n', height(T));
    
    % Optional CSV
    if ~isempty(csvOut)
        writetable(T, csvOut);
        fprintf('Wrote %s\n', csvOut);
    end
end

% ---- helpers ----
function v = getfield_try(s, fld, defaultVal)
    if isfield(s, fld) && ~isempty(s.(fld))
        v = s.(fld);
    else
        v = defaultVal;
    end
end

function t = sanitize_time(tin)
    t = char(string(tin));
    t = regexprep(t, '\D', '');
    if isempty(t), t = '000000'; end
    if numel(t) >= 6, t = t(1:6); else, t = pad(t, 6, 'right', '0'); end
end

function [anatomy_dicom, dest_folder, series_desc, idx, T2T] = pick_T2_series(cas, T, skipExistingCheck)
% PICK_T2_SERIES
% - Lists DICOM series and filters to T2
% - Lets user choose one
% - If anatomy/<cas.subj> already contains a folder, ask to replace it (unless skipped)
% - Returns the chosen SE path and destination folder

    if nargin < 5
        skipExistingCheck = false;
    end

    % --- list & filter T2 ---
    isT2 = ~cellfun(@isempty, regexpi(T.SeriesDescription, 'T2', 'once'));
    T2T  = T(isT2, :);
    if isempty(T2T)
        error('No series with "T2" found under: %s', cas.dir.patient);
    end

    % build choices and paths
    choices = strings(height(T2T),1);
    paths   = strings(height(T2T),1);
    for i = 1:height(T2T)
        choices(i) = sprintf('%s / %s / %s : Ser%03d  %s', ...
            T2T.PAT{i}, T2T.ST{i}, T2T.SE{i}, T2T.SeriesNumber(i), T2T.SeriesDescription{i});
        pth = fullfile(cas.dir.patient, T2T.PAT{i}, T2T.ST{i}, T2T.SE{i});
        if ~isfolder(pth)
            pth = fullfile(cas.dir.patient, T2T.ST{i}, T2T.SE{i});
            if ~isfolder(pth)
                pth = fullfile(cas.dir.patient, T2T.SE{i});
            end
        end
        paths(i) = pth;
    end

    % --- user picks series ---
    if height(T2T) > 1
        fprintf('\nT2 series found:\n');
        for i = 1:numel(choices), fprintf('%2d) %s\n', i, choices(i)); end
        idx = askInt('Enter the number of the series to use for anatomy: ', 1, numel(choices));
    else
        idx = 1;
        fprintf('\nOnly one T2 series found. Using:\n   %s\n', choices(1));
    end
    anatomy_dicom = char(paths(idx));
    series_desc   = regexprep(T2T.SeriesDescription{idx}, '[^\w\-]', '_');
    dest_folder   = fullfile(cas.dir.anatomy, series_desc);

    % --- optionally ask about replacing existing anatomy (if not skipped) ---
    if ~skipExistingCheck
        existing = dir(cas.dir.anatomy);
        existing = existing([existing.isdir] & ~ismember({existing.name},{'.','..'}));
        if ~isempty(existing)
            resp = askYN(sprintf('Anatomy already contains folder "%s". Replace it with "%s"? (y/n): ', ...
                                 existing(1).name, series_desc));
            if resp
                rmdir(fullfile(cas.dir.anatomy, existing(1).name), 's');
            else
                error('Aborted: user chose not to replace existing anatomy folder.');
            end
        end
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

    if contains(d,'foramen') || contains(d,'foreman') || contains(d,'magnum') || contains(d,'fm')
        if contains(d,' 5 ')
            sstt = 'FM-5';
        elseif contains(d,' 10 ')
            sstt = 'FM-10';
        elseif contains(d,' 15 ')
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
% Create:
%   <dest_base>/<base_name>_00
%   <dest_base>/<base_name>_MAG_01
%   <dest_base>/<base_name>_P_02
% Then:
%   - _00 keeps MR000000..MR000029 (removes others if any)
%   - _MAG_01 copies MR000030..MR000059
%   - _P_02 copies MR000000..MR000029
%
% src_path can have nested subfolders.

    % Sanitize base_name for filesystem safety (in case caller didn't)
    base_name = regexprep(base_name, '[^\w\-]', '_');
    base_name = regexprep(base_name, '_+', '_');
    base_name = regexprep(base_name, '^_+|_+$', '');
    if isempty(base_name), base_name = 'Series'; end

    dest00   = fullfile(dest_base, [base_name '_00']);
    destMAG  = fullfile(dest_base, [base_name '_MAG_01']);
    destP02  = fullfile(dest_base, [base_name '_P_02']);

    % Build directories
    createDirIfNotExists(dest_base);
    createDirIfNotExists(dest00);
    createDirIfNotExists(destMAG);
    createDirIfNotExists(destP02);

    % First: copy the whole source tree into _00, then prune by range
    % (Keeps any ancillary files/sidecars that aren’t MR* too.)
    fprintf('Copying full series to: %s\n', dest00);
    copyfile(src_path, dest00);

    % Collect all MR* files from source recursively once
    mrList = dir(fullfile(src_path, '**', 'MR*'));
    mrList = mrList(~[mrList.isdir]);  % files only

    % Helper: parse MR index e.g., MR000030 -> 30
    function n = mr_index(fname)
        % Accepts just name (MR000030.dcm) or full path; use basename
        [~, just] = fileparts(fname);
        tok = regexp(just, 'MR(\d+)', 'tokens', 'once');
        if isempty(tok)
            n = NaN;
        else
            n = str2double(tok{1});
        end
    end

    % Copy selected files into _MAG_01 and _P_02
    for k = 1:numel(mrList)
        srcFile = fullfile(mrList(k).folder, mrList(k).name);
        idx = mr_index(mrList(k).name);
        if isnan(idx), continue; end

        % 0..29 => goes to P_02 (copy)
        if idx >= 0 && idx <= 29
            rel = strrep(srcFile, [src_path filesep], '');  % relative path
            tgt = fullfile(destP02, rel);
            createDirIfNotExists(fileparts(tgt));
            copyfile(srcFile, tgt);
        end

        % 30..59 => goes to MAG_01 (copy)
        if idx >= 30 && idx <= 59
            rel = strrep(srcFile, [src_path filesep], '');
            tgt = fullfile(destMAG, rel);
            createDirIfNotExists(fileparts(tgt));
            copyfile(srcFile, tgt);
        end
    end

    % Prune _00 to keep only 0..29
    mrList00 = dir(fullfile(dest00, '**', 'MR*'));
    mrList00 = mrList00(~[mrList00.isdir]);
    for k = 1:numel(mrList00)
        f00 = fullfile(mrList00(k).folder, mrList00(k).name);
        idx = mr_index(mrList00(k).name);
        if ~isnan(idx) && ~(idx >= 0 && idx <= 29)
            delete(f00);
        end
    end

    rmdir(fullfile(dest_base, [base_name]), 's');

    fprintf('Organized into:\n  %s\n  %s\n  %s\n', dest00, destMAG, destP02);
end

