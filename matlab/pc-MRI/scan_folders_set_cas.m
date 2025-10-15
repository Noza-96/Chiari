function cas = scan_folders_set_cas(cas, out_folder)

    get_folders = fullfile(cas.dir.git, 'matlab', 'pc-MRI','get_folders.sh');
   
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
