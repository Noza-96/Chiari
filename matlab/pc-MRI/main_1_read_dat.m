%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear; clc
cas.subj = 's4'; cas.model = 'GE'; % GE (Utah) or SIEMENS (Granada)
cas = scan_folders_set_cas(cas);


resettimevector = false;

aux.fig_opts = set_plotting_style;
[aux.nt10, aux.klr] = define_colors;

disp([newline + "Setting up folders ..." + newline])

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


save(fullfile(cas.dirmat, "01-read_dat.mat"), 'aux', 'cas', 'dat_PC');

% Figure to visualize locations pc-mri measurements in read_dicoms_pc

disp([newline + "Done!" + newline])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
