function createDirIfNotExists(dirPath)
    if ~isfolder(dirPath)
        mkdir(dirPath);
    end
end