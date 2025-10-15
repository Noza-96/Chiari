%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cas, dat_PC] = main_1_read_dat(cas)

    % Auxiliary directories to clean or create
    out_folder = fullfile(tempdir, 'pc-MRI');

    cas = scan_folders_set_cas(cas, out_folder);

    resettimevector = false;

    if cas.Ncas > 0
        dat_PC = read_dicoms_PC(cas, resettimevector);
    else
        error("No PC DICOMS found!" + newline)
    end
    
    remove_temp_directories(out_folder);

end

function remove_temp_directories(out_folder)
    % Get all directories starting with 'aux' in out_folder
    d = dir(fullfile(out_folder, 'aux*'));
    for k = 1:numel(d)
        if d(k).isdir
            rmdir(fullfile(out_folder, d(k).name), 's'); % 's' removes contents recursively
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
