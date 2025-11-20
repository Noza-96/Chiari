function [cas, dat_PC] = read_MRI_data(cas)

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
    dirsToCreate = {cas.dir.anatomy, cas.dir.flow, cas.dir.mat, cas.dir.dat, cas.dir.ansys, cas.dir.ansys_out, cas.dir.ansys_in, cas.dir.ansys_profiles, cas.dir.vid, ... 
        cas.dir.seg, cas.dir.fig, cas.dir.reg, cas.dir.trans, fullfile(cas.dir.reg, 'pcMRI'), fullfile(cas.dir.reg, '2D-segmentation'), fullfile(cas.dir.reg, 'input-velocity'), fullfile(cas.dir.reg, 'output-velocity'), cas.dir.ROI, fullfile(cas.dir.seg, 'stl'), fullfile(cas.dir.ansys_in, "planes"), fullfile(cas.dir.ansys_in, "flow-rates"), fullfile(cas.dir.ansys_in, "case-files"), fullfile(cas.dir.ansys_in, "journals")};
    
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
    data_name = 'data_0.mat';
    
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
        [anatomy_dicom, dest_folder, series_desc, idx, T2T] = pick_T2_series(cas, T, true);
        copyfile(anatomy_dicom, dest_folder);
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
                fprintf ("\n\tOrdered from cranial to caudal direction (e.g., FM first, C1-C2 second, C3-C3, third)... \n")
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
                createDirIfNotExists(dest_path);
    
                % Base container: flow/zK-<sstt>/01PC/
                base_container = fullfile(z_folder, '01PC');
                createDirIfNotExists(base_container);
                
                % Organize into description_00, description_MAG_01, description_P_02
                split_flow_series(src_path, base_container, series_desc);
                
                z = z + 1;  % next slice level
            end
        end
        save(fullfile(cas.dir.mat, data_name),"cas");
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
        fprintf('\tNo series found under %s\n', rootDir);
        return
    end
    T = struct2table(data);
    T = sortrows(T, {'PAT','ST','SeriesNumber'});
    lastPAT = '';
    lastST  = '';
    for i = 1:height(T)
        if ~strcmp(lastPAT, T.PAT{i}) || ~strcmp(lastST, T.ST{i})
            fprintf('\n\t%s / %s\n', T.PAT{i}, T.ST{i});
            lastPAT = T.PAT{i}; lastST = T.ST{i};
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
        fprintf('\t\nT2 series found:\n\n');
        for i = 1:numel(choices), fprintf('\t\t%2d) %s\n', i, choices(i)); end
        fprintf('\n\t');
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
            resp = askYN(sprintf('- Anatomy already contains folder "%s". Replace it with "%s"? (y/n): ', ...
                                 existing(1).name, series_desc));
            if resp
                rmdir(fullfile(cas.dir.anatomy, existing(1).name), 's');
            else
                error('- Aborted: user chose not to replace existing anatomy folder.');
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
    fprintf('\n\tCopying full series to: %s\n', dest00);
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
            rel = split(srcFile, filesep);  % relative path
            rel = rel{end};
            tgt = fullfile(destP02, rel);
            createDirIfNotExists(fileparts(tgt));
            copyfile(srcFile, tgt);
        end

        % 30..59 => goes to MAG_01 (copy)
        if idx >= 30 && idx <= 59
            rel = split(srcFile, filesep);  % relative path
            rel = rel{end};
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

    rmdir(fullfile(dest_base, base_name), 's');

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

function dat  = read_dicoms_PC(cas)

    Ndat = length(cas.folders_);

    if strcmp(cas.model, 'GE')
        dicom_ext = 'MR*';
    elseif strcmp(cas.model, 'SIEMENS')
        dicom_ext = '*.dcm';
    end

    % Get data for each case and store in cell structures were first dimension is case number:

    pixel_coord = cell(1, Ndat);
    for idat = 1:Ndat
                
        dicomlist = dir(fullfile(cas.dir.flow, cas.folders_P{idat}, dicom_ext));

        numim = numel(dicomlist);

        % Run through all files and collect useful headers and image matrices:

        for jj = 1:numim

            fname = fullfile(cas.dir.flow,  cas.folders_P{idat}, dicomlist(jj).name);
            info{idat}{jj} = dicominfo(fname);

            % Identify manufacturer
            if idat == 1 && jj == 1
                if contains(upper(info{idat}{jj}.Manufacturer), 'SIEMENS')
                    cas.model = 'SIEMENS';
                    dicom_ext = '*.dcm';
                    
                elseif contains(upper(info{idat}{jj}.Manufacturer), 'GE')
                    cas.model = 'GE';
                    dicom_ext = 'MR*';
                end
            end

            % Hack to find VENC:
            if strcmp(cas.model, 'SIEMENS')
                command = sprintf('awk ''/^sAngio.sFlowArray.asElm\\[0\\].nVelocity/'' %s', fname);
                [status, sysout] = system(command);
                sysout = erase(sysout, "sAngio.sFlowArray.asElm[0].nVelocity");
                sysout = erase(sysout, "=");
                sysout = sysout(find(~isspace(sysout)));
                venc{idat}(jj) = str2num(sysout);
            elseif strcmp(cas.model, 'GE')
                venc{idat}(jj)        = 0.1 * double(info{idat}{jj}.(dicomlookup('0019', '10CC')));
                vencscale{idat}(jj)   = double(info{idat}{jj}.(dicomlookup('0019', '10E2')));
            end



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
        
        if isempty(cas.folders_MAG) == 1
            
            display("Magnitude images do not exist.")

            % Set magnitude images to zero.

            for jj = 1:numim
                
                immag_unsorted{idat}{jj} = zeros(size(im_unsorted{idat}{jj}));
                
            end

        else

            dicomlist = dir(fullfile(cas.dir.flow, cas.folders_MAG{idat}, dicom_ext));

            numim = numel(dicomlist);


            fname_showorient{idat} = fullfile(cas.dir.flow, cas.folders_MAG{idat}, dicomlist(1).name);

            for jj = 1:numim

                fname = fullfile(cas.dir.flow, cas.folders_MAG{idat}, dicomlist(jj).name);

                infomag{idat}{jj} = dicominfo(fname);

                immag_unsorted{idat}{jj} = double(dicomread(infomag{idat}{jj}));

            end

        end

        % Load DICOM files with stuff out of parallel directory for complementary use:

        dicomlist = dir(fullfile(cas.dir.flow, cas.folders_{idat}, dicom_ext));

        numim = numel(dicomlist);

        for jj = 1:numim

            fname = fullfile(cas.dir.flow, cas.folders_{idat}, dicomlist(jj).name);

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
        onepxarea{idat} = fcal_H_cm_px{idat} * fcal_V_cm_px{idat};

        for jj = 1:numim
            im{idat}{jj}    = im_unsorted{idat}{sortind(jj)};
            immag{idat}{jj} = immag_unsorted{idat}{sortind(jj)};
            imcom{idat}{jj} = imcom_unsorted{idat}{sortind(jj)};    
        end

        % Extract metadata for coordinate calculation
        pixel_spacing = info{idat}{1}.PixelSpacing; % [spacing_x; spacing_y]
        image_position = info{idat}{1}.ImagePositionPatient; % [x; y; z]
        image_orientation = info{idat}{1}.ImageOrientationPatient; % [row_dir_x; row_dir_y; row_dir_z; col_dir_x; col_dir_y; col_dir_z]
        
        % Directions
        row_direction = image_orientation(1:3);
        col_direction = image_orientation(4:6); 

        % Image dimensions
        [rows, cols] = size(dicomread(info{idat}{1}));
        
        % Preallocate array for coordinates
        pixel_coordinates = zeros(rows, cols, 3); % For (x, y, z) of each pixel
        
        % Calculate 3D coordinates for each pixel
        for i = 1:rows
            for j = 1:cols
            pixel_coordinates(i, j, :) = image_position ...
                                       + (j-1) * row_direction * pixel_spacing(1) ...
                                       + (i-1) * col_direction * pixel_spacing(2);

            end
        end

        % Store in cell for this case
        pixel_coord{idat} = pixel_coordinates;


        for jj = 1:numim

            % Save the acquisition times in seconds:

            t{idat}(jj) = double(triggertime{idat}(jj)) / 1000.0;

            phase{idat}(:, :, jj) = im{idat}{jj};
            magni{idat}(:, :, jj) = immag{idat}{jj};
            compl{idat}(:, :, jj) = imcom{idat}{jj};
            
            % Convert image pairs to velocity fields in cm/s:
            if strcmp(cas.model, 'GE')
                Vscale{idat}(jj) = pi * vencscale{idat}(jj) / venc{idat};
                U_tot{idat}(:, :, jj) = (phase{idat}(:, :, jj) ./ max(magni{idat}(:, :, jj), 1)) / Vscale{idat}(jj);
                
            elseif strcmp(cas.model, 'SIEMENS')
                U_tot{idat}(:, :, jj) = - venc{idat} .* ( (phase{idat}(:, :, jj) - 2048) ./ 2048 );
            end

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

        t{idat} = (0:(Nt{idat}-1))/Nt{idat};
        
        % Save the slice location in cm:

        locz{idat} = location{idat} - location{1};
        
    end

    fprintf('\nList of all cases:\n')
    for idat = 1:Ndat
        disp([num2str(idat, '%02d'), '  -  ', cas.names{idat}])
    end

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
    dat.onepxarea   = onepxarea;
    dat.locations = cas.locations;

end

