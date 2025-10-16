function [cas, dat_PC] = read_MRI_data(cas)

    fprintf('1) Setup subject and extract MRI data...\n')
    %% Create directories
    cas = create_directories(cas);

    if hasContent(cas.dir.anatomy) && hasContent(cas.dir.flow)
        if askYN('- MRI data already extracted. Skip? ([y]/n): ')
            load(fullfile(cas.dir.mat, 'data_0.mat'), 'cas', 'dat_PC');
            return;
        end
    end

    %% 
    fprintf('\nOrganize DICOM data...\n')
    cas = organize_DICOMS(cas);

    %% 
    fprintf('\nExtract PC-MRI data...\n')
    [cas, dat_PC] = main_1_read_dat(cas);
    
    %% 
    file_name = "data_0.mat";
    fprintf("Saving everything in %s file ...\n", file_name)
    save(fullfile(cas.dir.mat, file_name), 'cas','dat_PC');
end