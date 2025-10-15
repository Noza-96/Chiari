function tf = hasContent(folder)
% Return true if folder exists and has anything inside (ignores . and ..)

    tf = isfolder(folder) && numel(dir(fullfile(folder,'*'))) > 2;
end