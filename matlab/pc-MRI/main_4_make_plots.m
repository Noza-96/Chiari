%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save_figs = true;

% Here we plot all the data, in step 5 we select only the good data:
idat_sel = 1:dat_PC.Ndat;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot_Q(aux, cas, dat_PC, save_figs, idat_sel, 'all');
% 
% plot_SVQ(aux, cas, dat_PC, save_figs, idat_sel, 'all');

% make_movies_imshow(cas, dat_PC, 'all4', 1:dat_PC.Ndat, true);

make_movies_imshow(cas, dat_PC, 'U_sas', 1:dat_PC.Ndat, true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
