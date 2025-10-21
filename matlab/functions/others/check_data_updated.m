function [cas, dat_PC, didSkip] = check_data_updated(cas, data_now, data_prev, dlist) 

    if ~exist(fullfile(cas.dir.mat, data_prev), 'file')
        error("- %s does not exist, need to run previous steps...\n", data_prev)
    else
        load(fullfile(cas.dir.mat, data_prev), 'cas', 'dat_PC');
    end

    didSkip = false;
    d_prev = dir(fullfile(cas.dir.mat,data_prev));
    d_now = dir(fullfile(cas.dir.mat,data_now));

    latestDate = d_prev.datenum;
    if nargin > 3 
        if ~isempty(dlist)
            latestDate = max([dlist.datenum, d_prev.datenum]); 
        end
    end
    
    if exist(fullfile(cas.dir.mat, data_now), 'file')
        if datetime(latestDate, 'ConvertFrom', 'datenum') > datetime(d_now.datenum, 'ConvertFrom', 'datenum')
            fprintf("- Data needs to be updated...\n")
            return
        else
            if askYN('- Data up to date. Skip? ([y]/n): ')
                fprintf('\n')
                load(fullfile(cas.dir.mat, data_now), 'cas', 'dat_PC');
                didSkip = true;
                return;
            end
        end
    else
        fprintf("- Reading data for the first time...\n")
    end


end