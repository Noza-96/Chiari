function cas = create_directories(cas)
% - Create directories
    cas.dir.chiari          = full_path(fullfile(pwd, '..', '..'));
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
    cas.dir.trans            = fullfile(cas.dir.seg,'transformation');

    % List of directories to ensure exist
    dirsToCreate = {cas.dir.anatomy, cas.dir.flow, cas.dir.mat, cas.dir.dat, cas.dir.ansys, cas.dir.ansys_out, cas.dir.ansys_in, cas.dir.ansys_profiles, cas.dir.vid, ... 
        cas.dir.seg,cas.dir.fig, cas.dir.ROI,fullfile(cas.dir.seg, 'stl'), fullfile(cas.dir.ansys_in, "planes"), fullfile(cas.dir.ansys_in, "flow-rates"), fullfile(cas.dir.ansys_in, "case-files"), fullfile(cas.dir.ansys_in, "journals")};
    
    % Create directories if not present
    for i = 1:length(dirsToCreate)
        createDirIfNotExists(dirsToCreate{i});
    end
end

