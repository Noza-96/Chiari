% Select good cases and represent final figures, fourier data etc.

idat_sel = [2, 3, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18];

save_figs = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plot_Q(aux, cas, dat_PC, save_figs, idat_sel, 'sel');

plot_SVQ(aux, cas, dat_PC, save_figs, idat_sel, 'sel');

write_fourier(cas, dat_PC, idat_sel);

