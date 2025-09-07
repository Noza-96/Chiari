%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear; close all; 

[aux, cas, dat_PC, single_reading] = run_if_empty('s4', 'GE');  % if skipping previous steps

disp("Applying ROIs and computing Q ..." + newline)

visualization_plots = true;

correct_aliasing = false; % wrap in time - aliasing correction
unwrap_periodic = false; % allow for periodic wraping
smooth_spatial_outliers = false;  % Flag to apply spatial outlier smoothing
gauss_filter = false; % apply gauss filter

dat_PC = apply_ROI_compute_Q(dat_PC, correct_aliasing, unwrap_periodic, smooth_spatial_outliers, gauss_filter);

disp(["Repeating and interpolating Q ..." + newline])

dat_PC = repeat_interpolate_Q(dat_PC);

disp(["Computing SV and zero correction ..." + newline])

dat_PC = compute_SVQ_zc(dat_PC);

disp(["Fourier decomposition ..." + newline])

dat_PC = decompose_fourier(cas, dat_PC);

disp("Saving everything in a .mat file ..." + newline)

if isempty(single_reading) 
    sstt_name = "";
else
    sstt_name = strjoin(cellstr(string(single_reading)), '-');
    if ~endsWith(sstt_name, '-')
    sstt_name = sstt_name + "-";
    end
end

save(fullfile(cas.dirmat, "03-"+sstt_name+"apply_roi_compute_Q.mat"), 'aux', 'cas', 'dat_PC');

disp( "Done!" + newline)

if visualization_plots
    
    % plot_flow_rates(dat_PC, cas);  

    ts_cycle = 40; 
    movieVector = create_animation(dat_PC, cas, ts_cycle);
    
    % save_animation(movieVector, fullfile(cas.dirvid, "flow_measurements_"+cas.subj+".mp4"));
end


function [aux, cas, dat_PC, single_reading] = run_if_empty(subject, model)
        cas.subj = subject;
        cas.model = model; % GE (Utah) or SIEMENS (Granada)
        single_reading = {};
        cas = scan_folders_set_cas(cas, single_reading);
        load([cas.dirmat, '/02-crop_set_roi.mat'], 'aux', 'cas', 'dat_PC');
end


function plot_flow_rates(velocity, cas)
    N = length(cas.locations);  % number of slices
    figure('Units', 'normalized', 'Position', [0.1 0.2 0.1 0.6]);
    tiledlayout(ceil(N), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:N
        nexttile
        Q = - velocity.Q_SAS{i};       % flow rate
        flow_rate(Q)
        ylim([-2,2])
        xlabel('Time [s]')
        ylabel('Flow rate [mm^3/s]')
        title(cas.locations{i}, 'Interpreter', 'none')
        grid on
    end

    sgtitle("Flow Rates over Time", 'FontWeight', 'bold');
end
