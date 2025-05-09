%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

cas.subj = 's101_aa';

cas.model = 'SIEMENS'; % GE (Utah) or SIEMENS (Granada)

% allow to filter folders. If single_reading = {} all cases
single_reading = {}; 

resettimevector = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

aux.fig_opts = set_plotting_style;
[aux.nt10, aux.klr] = define_colors;

disp([newline + "Setting up folders ..." + newline])

cas = scan_folders_set_cas(cas, single_reading);

if cas.Ncas_PC > 0
    disp(["Reading PC DICOMS ..." + newline])
    dat_PC = read_dicoms_PC(cas, resettimevector);
end

if cas.Ncas_RT > 0
    disp(["Reading RT DICOMS ..." + newline])
    dat_RT = read_dicoms_RT(cas, resettimevector);
end

if cas.Ncas_FM > 0
    disp(["Reading FM DICOMS ..." + newline])
    dat_FM = read_dicoms_FM(cas);ilapps
end

disp(["Saving everything in a .mat file ..." + newline])


if isempty(single_reading) 
    sstt_name = "";
else
    sstt_name = strjoin(cellstr(string(single_reading)), '-');
    if ~endsWith(sstt_name, '-')
    sstt_name = sstt_name + "-";
    end
end

save(fullfile(cas.dirmat, "01-"+sstt_name+"read_dat.mat"), 'aux', 'cas', 'dat_PC');

% Figure to visualize locations pc-mri measurements in read_dicoms_pc

disp([newline + "Done!" + newline])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
