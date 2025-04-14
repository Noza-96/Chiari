function cas = scan_folders_set_cas(cas, single_reading)

% Computations folder
cas.dircloud = fullfile('..', '..', '..','computations');
% DICOM folder
cas.dirdcm = fullfile('..', '..', '..','patient-data',cas.subj,'flow');

% Save data folder
cas.dirdat = fullfile(cas.dircloud,'pc-mri');

% Define directories with a modular structure
cas.dirmat = fullfile(cas.dirdat, cas.subj, 'mat');
cas.dirflm = fullfile(cas.dirdat, cas.subj, 'flm');
cas.dirvid = fullfile(cas.dircloud, 'videos', cas.subj);
cas.dirfig = fullfile(cas.dircloud, 'figures', cas.subj);
cas.dirROI = fullfile(cas.dirmat,'ROIs');


cas.diransys = fullfile(cas.dircloud, 'ansys', cas.subj);
cas.diransys_out = fullfile(cas.diransys, 'outputs');
cas.diransys_in = fullfile(cas.diransys, 'inputs');
cas.diransys_profiles = fullfile(cas.diransys_in, 'profiles');
cas.dirseg = fullfile(cas.dircloud, 'segmentation', cas.subj);

% List of directories to ensure exist
dirsToCreate = {cas.dirmat, cas.diransys, cas.diransys_out, cas.diransys_in, cas.diransys_profiles, cas.dirvid, cas.dirseg, cas.dirfig, cas.dirROI};

% Create directories if not present
for i = 1:length(dirsToCreate)
    createDirIfNotExists(dirsToCreate{i});
end

% Auxiliary directories to clean or create
auxDirs = {'./aux_PC', './aux_RT', './aux_FM'};
for i = 1:length(auxDirs)
    createOrCleanDir(auxDirs{i});
end

    system('cp get_folders_PC.sh ./aux_PC');
    system('cp get_folders_RT.sh ./aux_RT');
    system('cp get_folders_FM.sh ./aux_FM');

    commstr_PC = strcat("sed -i 's|dummyfoldertoreplace|", cas.dirdcm, "|g' ./aux_PC/get_folders_PC.sh");
    commstr_RT = strcat("sed -i 's|dummyfoldertoreplace|", cas.dirdcm, "|g' ./aux_RT/get_folders_RT.sh");
    commstr_FM = strcat("sed -i 's|dummyfoldertoreplace|", cas.dirdcm, "|g' ./aux_FM/get_folders_FM.sh");

    system(commstr_PC);
    system(commstr_RT);
    system(commstr_FM);
    
    system('sh ./aux_PC/get_folders_PC.sh');
    system('sh ./aux_RT/get_folders_RT.sh');
    system('sh ./aux_FM/get_folders_FM.sh');

    strfolders_PC = fileread('./aux_PC/folders.txt');
    folders_PC = regexp(strfolders_PC, '\r\n|\r|\n', 'split');
    folders_PC(end) = [];
    
    strfolders_PC_ = fileread('./aux_PC/folders_.txt');
    folders_PC_ = regexp(strfolders_PC_, '\r\n|\r|\n', 'split');
    folders_PC_(end) = [];

    strfolders_PC_P = fileread('./aux_PC/folders_P.txt');
    folders_PC_P = regexp(strfolders_PC_P, '\r\n|\r|\n', 'split');
    folders_PC_P(end) = [];

    strfolders_PC_MAG = fileread('./aux_PC/folders_MAG.txt');
    folders_PC_MAG = regexp(strfolders_PC_MAG, '\r\n|\r|\n', 'split');
    folders_PC_MAG(end) = [];

    % fileter folders to those containing single reading
    if ~isempty(single_reading)
        folders_PC = filter_folders_by_keywords(folders_PC, single_reading);
        folders_PC_ = filter_folders_by_keywords(folders_PC_, single_reading);
        folders_PC_P = filter_folders_by_keywords(folders_PC_P, single_reading);
        folders_PC_MAG = filter_folders_by_keywords(folders_PC_MAG, single_reading);
    end

    strfolders_RT = fileread('./aux_RT/folders.txt');
    folders_RT = regexp(strfolders_RT, '\r\n|\r|\n', 'split');
    folders_RT(end) = [];
    
    strfolders_RT_ = fileread('./aux_RT/folders_.txt');
    folders_RT_ = regexp(strfolders_RT_, '\r\n|\r|\n', 'split');
    folders_RT_(end) = [];

    strfolders_RT_P = fileread('./aux_RT/folders_P.txt');
    folders_RT_P = regexp(strfolders_RT_P, '\r\n|\r|\n', 'split');
    folders_RT_P(end) = [];

    strfolders_RT_MAG = fileread('./aux_RT/folders_MAG.txt');
    folders_RT_MAG = regexp(strfolders_RT_MAG, '\r\n|\r|\n', 'split');
    folders_RT_MAG(end) = [];

    strfolders_FM = fileread('./aux_FM/folders.txt');
    folders_FM = regexp(strfolders_FM, '\r\n|\r|\n', 'split');
    folders_FM(end) = [];
    
    strfolders_FM_ = fileread('./aux_FM/folders_.txt');
    folders_FM_ = regexp(strfolders_FM_, '\r\n|\r|\n', 'split');
    folders_FM_(end) = [];
    
    folders_FM_P   = folders_FM;
    folders_FM_P(:) = {''};

    folders_FM_MAG = folders_FM;
    folders_FM_MAG(:) = {''};
    
    Ncas_PC = length(folders_PC);
    Ncas_RT = length(folders_RT);
    Ncas_FM = length(folders_FM);
    
    if Ncas_PC > 0
        for nn = 1:Ncas_PC
            % include only data 
            ind = strfind(folders_PC{nn}, '/')-1;
            ind = ind(1);
            locations_PC{nn} = folders_PC{nn}(4:ind);
            names_PC{nn} = strrep(folders_PC{nn},'/','-');
            zones_PC{nn} = folders_PC{nn}(1:2);
            icas_PC{nn} = str2num(folders_PC{nn}(11:12));
            tech_PC{nn} = 'PC';
        end
    else
        folders_PC = {};
        folders_PC_ = {};
        folders_PC_P = {};
        folders_PC_MAG = {};
        names_PC = {};
        zones_PC = {};
        locations_PC = {};
        icas_PC = {};
        tech_PC = {};
    end

    if Ncas_RT > 0
        for nn = 1:Ncas_RT
            names_RT{nn} = strrep(folders_RT{nn},'/','-');
            zones_RT{nn} = folders_RT{nn}(1:2);
            ind = strfind(folders_RT{nn}, '/')-1;
            ind = ind(1);
            locations_RT{nn} = folders_RT{nn}(4:ind);
            icas_RT{nn} = str2num(folders_RT{nn}(11:12));
            tech_RT{nn} = 'RT';
        end
    else
        folders_RT = {};
        folders_RT_ = {};
        folders_RT_P = {};
        folders_RT_MAG = {};
        names_RT = {};
        zones_RT = {};
        locations_RT = {};
        icas_RT = {};
        tech_RT = {};
    end

    if Ncas_FM > 0
        for nn = 1:Ncas_FM
            names_FM{nn} = strrep(folders_FM{nn},'/','-');
            zones_FM{nn} = folders_FM{nn}(1:2);
            ind = strfind(folders_FM{nn}, '/')-1;
            ind = ind(1);
            locations_FM{nn} = folders_FM{nn}(4:ind);
            icas_FM{nn} = str2num(folders_FM{nn}(11:12));
            tech_FM{nn} = 'FM';
        end
    else
        folders_FM = {};
        folders_FM_ = {};
        folders_FM_P = {};
        folders_FM_MAG = {};
        names_FM = {};
        zones_FM = {};
        locations_FM = {};
        icas_FM = {};
        tech_FM = {};
    end
    
    cas.Ncas_PC        = Ncas_PC;
    cas.Ncas_RT        = Ncas_RT;
    cas.Ncas_FM        = Ncas_FM;
    cas.folders_PC     = folders_PC;
    cas.folders_RT     = folders_RT;
    cas.folders_FM     = folders_FM;
    cas.folders_PC_    = folders_PC_;
    cas.folders_RT_    = folders_RT_;
    cas.folders_FM_    = folders_FM_;
    cas.folders_PC_P   = folders_PC_P;
    cas.folders_RT_P   = folders_RT_P;
    cas.folders_FM_P   = folders_FM_P;
    cas.folders_PC_MAG = folders_PC_MAG;
    cas.folders_RT_MAG = folders_RT_MAG;
    cas.folders_FM_MAG = folders_FM_MAG;
    cas.names_PC       = names_PC;
    cas.names_RT       = names_RT;
    cas.names_FM       = names_FM;
    cas.zones_PC       = zones_PC;
    cas.zones_RT       = zones_RT;
    cas.zones_FM       = zones_FM;
    cas.locations_PC   = locations_PC;
    cas.locations_RT   = locations_RT;
    cas.locations_FM   = locations_FM;
    cas.icas_PC        = icas_PC;
    cas.icas_RT        = icas_RT;
    cas.icas_FM        = icas_FM;
    cas.tech_PC        = tech_PC;
    cas.tech_RT        = tech_RT;
    cas.tech_FM        = tech_FM;
    
    folders     = [folders_PC    , folders_RT    , folders_FM    ];
    folders_    = [folders_PC_   , folders_RT_   , folders_FM_   ];
    folders_P   = [folders_PC_P  , folders_RT_P  , folders_FM_P  ];
    folders_MAG = [folders_PC_MAG, folders_RT_MAG, folders_FM_MAG];
    names       = [names_PC      , names_RT      , names_FM      ];
    zones       = [zones_PC      , zones_RT      , zones_FM      ];
    locations   = [locations_PC  , locations_RT  , locations_FM  ];
    icas        = [icas_PC       , icas_RT       , icas_FM       ];
    tech        = [tech_PC       , tech_RT       , tech_FM       ];
    
    Ncas = Ncas_PC + Ncas_RT + Ncas_FM;
    
    cas.Ncas        = Ncas;
    cas.folders     = folders;
    cas.folders_    = folders_;
    cas.folders_P   = folders_P;
    cas.folders_MAG = folders_MAG;
    cas.names       = names;
    cas.zones       = zones;
    cas.locations   = locations;
    cas.icas        = icas;
    cas.tech        = tech;

end


% Helper function to create a directory if it does not exist
function createDirIfNotExists(dirPath)
    if ~isfolder(dirPath)
        mkdir(dirPath);
    end
end

% Helper function to clean or create a directory
function createOrCleanDir(dirPath)
    if ~isfolder(dirPath)
        mkdir(dirPath);
    else
        rmdir(fullfile(dirPath, '*'));
    end
end

function absolutePath = full_path(folder_path)
    absolutePath = char(java.io.File(folder_path).getCanonicalPath());
end

function filtered = filter_folders_by_keywords(folders, keywords)
% FILTER_FOLDERS_BY_KEYWORDS Filters a cell array of folder paths
%   Only matches keywords that appear directly after 'flow/z#-' in the path.

    folders_str = string(folders);
    keywords_str = string(keywords);

    % Initialize logical index
    keep_idx = false(size(folders_str));

    % Loop through folder paths
    for i = 1:numel(folders_str)
        % Extract identifier after 'flow/z#-'
        tokens = regexp(folders_str(i), "z\d+-(\w+)", "tokens");
        if ~isempty(tokens)
            id = tokens{1}{1}; % Get the matched part after 'z#-'
            for j = 1:numel(keywords_str)
                if strcmp(id, keywords_str(j)) % exact match only
                    keep_idx(i) = true;
                    break;
                end
            end
        end
    end

    % Return filtered folders
    filtered = cellstr(folders_str(keep_idx));
end