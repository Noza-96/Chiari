%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

cas.subj = 's101';
cas.sess = 'before';
cas.model = 'SIEMENS'; % GE (Utah) or SIEMENS (Granada)

cas.dircloud = '../../../computations'; % (do not include ending "/" in cas.dirdat)

cas.dirdat = [cas.dircloud,'/pc-mri'];

cas.dir_fullpath_ansys = "C:/Users/guill/Documents/chiari/computations/ansys"; % needed for ansys computations

cas.anal = 'flow';

resettimevector = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

aux.fig_opts = set_plotting_style;
[aux.nt10, aux.klr] = define_colors;

disp([newline + "Setting up folders ..." + newline])

cas = scan_folders_set_cas(cas);

if cas.Ncas_PC > 0
    disp([newline + "Reading PC DICOMS ..." + newline])
    dat_PC = read_dicoms_PC(cas, resettimevector);
end

if cas.Ncas_RT > 0
    disp([newline + "Reading RT DICOMS ..." + newline])
    dat_RT = read_dicoms_RT(cas, resettimevector);
end

if cas.Ncas_FM > 0
    disp([newline + "Reading FM DICOMS ..." + newline])
    dat_FM = read_dicoms_FM(cas);
end

disp([newline + "Saving everything in a .mat file ..." + newline])

save([cas.dirmat, '/01-read_dat.mat'], 'aux', 'cas', 'dat_PC');

% Figure to visualize locations pc-mri measurements in read_dicoms_pc

disp([newline + "Done!" + newline])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
