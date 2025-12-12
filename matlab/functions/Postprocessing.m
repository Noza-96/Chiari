%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clc; clear; close all;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101_b";

% c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
% case_name = { "c2", "c1t", "c1b","c0t"}; 
case_name = {"cnl3_v1"};
mesh_size = 0.0002;
ts_cycle = 100;
cycle = 3; 

% read ansys reports and save solution in .mat file
[cas, dat_PC, pcmri, DNS] = read_ansys_reports(subject, case_name, mesh_size, ts_cycle, cycle, 1);

%% Animation comparison PC-MRI with Ansys solution -- Animation
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas', 'dat_PC');
case_name ={"cnl3_v1"};
mesh_size = [0.00015];
ts_cycle = 100; 
cycle = 3;
warning('off', 'all');
comparison_results(cas, case_name, mesh_size, ts_cycle, cycle)
warning('on', 'all');

%% snapshots - bcs
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
% case_name ={"c0t", "c1t", "c1b"};
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = [0.0002];
ts_cycle = 100*ones(1,length(case_name));
cycles = 3*ones(1,length(case_name));
warning('off', 'all');
selected_times = [40, 70, 80];
snapshot_results(cas, case_name, mesh_size, ts_cycle, cycles, selected_times)
warning('on', 'all');

%% pressure - bcs
close all; clear;
subject = "s101_b";
case_name ={"c0t", "c1t", "c1b", "c2", "c3"};
mesh_size = 0.0002;
ts_cycle = 100;
cycles = 3;
fig_pressure(subject, case_name, mesh_size, ts_cycle, cycles);

%% snapshots - anatomy
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c3", "cn3_v1", "cl3_v1",  "cnl3_v1"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 70, 80];
ts_cycle = 100*ones(1,length(case_name));
cycles = 3*ones(1,length(case_name));
snapshot_results(cas, case_name, mesh_size, ts_cycle, cycles, selected_times)
warning('on', 'all');

%% pressure - anatomy
close all; clear;
subject = "s101_b";
case_name ={"c3", "cn3_v1", "cl3_v1",  "cnl3_v1"};
mesh_size = [0.0002];
[ZL,LI] = fig_pressure(subject, case_name, mesh_size);


%% snapshots - anatomy I-V
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');
case_name ={"c0t", "cnl0_v1_ts_100_N_3", "cnl3_v1"};
mesh_size = [0.0002];
warning('off', 'all');
selected_times = [40, 70, 80];
ts_cycle = 100*ones(1,length(case_name));
cycles = 3*ones(1,length(case_name));
snapshot_results(cas, case_name, mesh_size, ts_cycle, cycles, selected_times)
warning('on', 'all');

%% figure 9 - anterior-posterior flow 
figure_9;

%% figure 10 - anterior-posterior pressure 
figure_10;

%% table - sensitivity mesh
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');

case_name ="cnl3_v1";
mesh_size = [0.0004, 0.0002, 0.00015];
ts = 100; 
cyc = 3;

[st_DNS] = compute_error (cas,mesh_size, ts, cyc, case_name);

stats = SensitivityAnalysis(st_DNS);

table_error (stats, 'dx', mesh_size*1000)

%% table - sensitivity cycles
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');

case_name ="cnl3_v1";
mesh_size = 0.0002;
ts = 100; 
cyc = [2, 3, 10];

[st_DNS] = compute_error (cas,mesh_size, ts, cyc, case_name);

stats = SensitivityAnalysis(st_DNS);

table_error (stats, 'cycles', cyc)

%% table - time step
close all; clear;
subject = "s101_b";
load(fullfile("../../../computations", "pc-mri", subject, "mat", "04-registration.mat"), 'cas');

case_name ="cnl3_v1";
mesh_size = 0.0002;
ts = [50, 100, 200]; 
cyc = 3;

[st_DNS] = compute_error (cas,mesh_size, ts, cyc, case_name);

stats = SensitivityAnalysis(st_DNS);

table_error (stats, 'dt/T', ts)


%%%%%%%%%%%%%%%%%%%%%%%%%%%

function table_error (stats, param, val)
    u_rel = stats.L2_u*100;            % size: Ncases × 3 slices
    RMSE_rel = stats.RMSE_rel*100;
    p_rel = stats.p_rel(:)*100;         % size: Ncases × 1 (global pressure error)
    
    % Column names
    varNames = {...
        param, ...
        'u_rel_FM', 'u_rel_C1C2', 'u_rel_C2C3', 'p_rel'};
    
    % Build table
    T = table( val(1:length(u_rel(:,2)))', ...
               u_rel(:,2), u_rel(:,3), u_rel(:,4), p_rel, ...
               'VariableNames', varNames);
    
    disp(T)
end


function st_DNS = compute_error(cas, mesh_size, ts, cyc, case_name)

    % Make sure everything is a row vector / string array
    mesh_size = mesh_size(:).';
    ts        = ts(:).';
    cyc       = cyc(:).';
    case_name = string(case_name(:).');

    % Determine number of cases
    N_cases = max([numel(mesh_size), numel(ts), numel(cyc), numel(case_name)]);

    % Replicate scalars to length N_cases
    if numel(mesh_size) == 1, mesh_size = repmat(mesh_size, 1, N_cases); end
    if numel(ts)        == 1, ts        = repmat(ts,        1, N_cases); end
    if numel(cyc)       == 1, cyc       = repmat(cyc,       1, N_cases); end
    if numel(case_name) == 1, case_name = repmat(case_name, 1, N_cases); end

    DNS_cases = cell(1, N_cases);
    st_DNS    = cell(1, N_cases);

    for ii = 1:N_cases
        [t_geom, t_sim, b_inlet, version] = get_type_simulation(case_name(ii));

        DNS_cases{ii} = t_geom + string(t_sim) + b_inlet + "_dx" + formatDecimal(mesh_size(ii)) ...
            + version + "_ts_" + ts(ii) + "_N_"  + cyc(ii);

        load(fullfile(cas.dirmat, "DNS-results", "comparisons-error", "DNS_" + DNS_cases{ii} + ".mat"), 'DNS');

        st_DNS{ii} = DNS;
    end
end

% ---------------------------------------------
% Plot velocity waveform for all slices
% ---------------------------------------------

function plot_error (st_DNS, stats, leg)

    figure;
    set(gcf, 'Position', [200 200 1200 350]);
    
    sliceNames = {'FM-C1', 'C1-C2', 'C2-C3'};
    nslices = 3;
    
    Ncases = numel(st_DNS) - 1;    % meshes compared to finest reference
    
    % Time vector
    Nt = size(st_DNS{1}.RMSE_space.u_normal{1}, 2);
    t = linspace(0, 1, Nt);   % normalized cardiac cycle
    
    % Create tiled layout
    tiledlayout(1, nslices , 'TileSpacing', 'compact', 'Padding', 'compact');
    
    for s = 1:nslices
        nexttile; hold on; box on;
    
        for m = 1:Ncases
            plot(t, stats.relErr_L1{m,s}, 'LineWidth', 1.5);
        end
        set(gca, 'LineWidth', 1, 'TickLength', [0.01, 0.01]);
        set(gca,"FontSize",12)
        xlabel('$t/T$', Interpreter='latex', FontSize=20);
        yticks(0:0.02:0.20);       % adjust range as needed
        ylabel('$\varepsilon^{(u)}$', Interpreter='latex', FontSize=20);
        title(sliceNames{s}, FontSize=20,Interpreter='latex');
        % legend('show', 'Location', 'best');
        ylim([0,0.15])
        % yticklabels(0:0.02:0.2)
        grid on
        ax = gca;
        ax.XGrid = 'off';
        ax.YGrid = 'on';
        set(gca, 'GridAlpha', 0.1); 
        set(gcf, 'Color', 'w');  
        if s == 1
        legend(leg, Interpreter="latex",FontSize=16)
        end
    end
end

function stats = SensitivityAnalysis(st_DNS, ref_idx, tol)
%MESH SENSITIVITY ANALYSIS ON COMMON PIXELS ONLY
%
% stats = meshSensitivityCommon(st_DNS)
% stats = meshSensitivityCommon(st_DNS, ref_idx)
% stats = meshSensitivityCommon(st_DNS, ref_idx, tol)
%
% INPUTS
%   st_DNS  : 1 x Ncases cell array, each cell is a DNS struct like:
%             st_DNS{i}.RMSE_space.x{s}        [Ni x 1]
%             st_DNS{i}.RMSE_space.y{s}        [Ni x 1]
%             st_DNS{i}.RMSE_space.u_normal{s} [Ni x Nt]
%             st_DNS{i}.mesh_size              (scalar)
%
%   ref_idx : index of reference mesh (default: Ncases, usually finest)
%   tol     : spatial tolerance for matching points (default: 1e-6)
%
% OUTPUT (in struct "stats")
%   stats.ref_idx           : index of reference mesh
%   stats.ref_mesh_size     : mesh size of reference
%   stats.mesh_idx          : indices of meshes compared to reference
%   stats.mesh_size         : mesh sizes of compared meshes
%   stats.nslices           : number of slices
%   stats.Nt                : number of time steps
%
%   stats.Ncommon(i,s)      : number of common pixels, mesh i vs ref, slice s
%   stats.RMSE_space_time(i,s)
%                           : scalar space–time RMSE over common pixels
%   stats.RMSE_t{i,s}       : 1 x Nt vector, RMSE(t) over space for each time
%
%   (i runs over compared meshes, s over slices)
%
% EXAMPLE:
%   stats = meshSensitivityCommon(st_DNS);
%   disp(stats.RMSE_space_time)
%
%   % Show table for slice 1:
%   T = table(stats.mesh_size(:), stats.RMSE_space_time(:,1), stats.Ncommon(:,1), ...
%             'VariableNames', {'dx','RMSE_slice1','Ncommon'});
%   disp(T);

    % ---------------- Default inputs ----------------
    if nargin < 2 || isempty(ref_idx)
        ref_idx = numel(st_DNS);   % assume last is finest
    end

    if nargin < 3 || isempty(tol)
        tol = 1e-6;                % spatial tolerance (in same units as x,y)
    end

    % ---------------- Basic info ----------------
    Ncases  = numel(st_DNS);
    nslices = numel(st_DNS{ref_idx}.RMSE_space.u_normal);
    Nt      = size(st_DNS{ref_idx}.RMSE_space.u_normal{1}, 2);
    Nm = Ncases-1;

    % ---------------- Allocate outputs ----------------
    Ncommon          = zeros(Nm, nslices);
    RMSE_space_time  = nan(Nm, nslices);
    RMSE_t           = cell(Nm, nslices);  % each is 1 x Nt
    RMSE_rel = zeros(Nm, nslices);
    relErr_space_time = nan(Nm, nslices);
    relErr_t          = cell(Nm, nslices);
    dp                = cell(Nm, 1);
    rel_p             = nan(Nm,1);
    u_rel             = nan(Nm, nslices);
    relErr_L1_t = cell(Nm, nslices);

    ts_base = min(cellfun(@(S) S.ts_cycle, st_DNS));

    % ---------------- Main loops ----------------
    for im = 1:Nm
        m = im;  

        % --- reference ---
        ts_ref   = st_DNS{ref_idx}.ts_cycle;
        stride_r = ts_ref / ts_base;
    
        % --- mesh m ---
        ts_m   = st_DNS{m}.ts_cycle;
        stride_m = ts_m / ts_base;

        if abs(round(stride_r) - stride_r) > 1e-6 || abs(round(stride_m) - stride_m) > 1e-6
            error('ts_cycle of ref or case %d is not an integer multiple of ts_base; consider time interpolation instead.', m);
        end

        stride_r = round(stride_r);
        stride_m = round(stride_m);

        dp_ref_0 = st_DNS{ref_idx}.out.dp.val{2};
        dp_ref_25 = st_DNS{ref_idx}.out.dp.val{7};

        dp_ref_0 = dp_ref_0  (end-ts_ref+1 : stride_r : end);
        dp_ref_25 = dp_ref_25(end-ts_ref+1 : stride_r : end);

        dp_m_0 = st_DNS{m}.out.dp.val{2};
        dp_m_25 = st_DNS{m}.out.dp.val{7};

        dp_m_0 = dp_m_0  (end-ts_m+1 : stride_m : end);
        dp_m_25 = dp_m_25(end-ts_m+1 : stride_m : end);


        dp_ref   = dp_ref_0 - dp_ref_25;
        dp_m     = dp_m_0 - dp_m_25;

        dp_ref_t = max(abs(dp_ref));
        dp_m_t   = max(abs(dp_m));

        rel_p(im) = abs(dp_ref_t - dp_m_t)/dp_ref_t;
        dp{im}    = abs(dp_ref - dp_m)./abs(dp_ref);

        for s = 1:nslices
            % ---- Reference mesh data ----
            x_ref = st_DNS{ref_idx}.RMSE_space.x{s};
            y_ref = st_DNS{ref_idx}.RMSE_space.y{s};
            U_ref = st_DNS{ref_idx}.RMSE_space.u_int{s};   % [Nref x Nt]
            RMSE_ref = st_DNS{ref_idx}.RMSE_ave{s};

            % ---- Mesh m data ----
            x_m = st_DNS{m}.RMSE_space.x{s};
            y_m = st_DNS{m}.RMSE_space.y{s};
            U_m = st_DNS{m}.RMSE_space.u_int{s};           % [Nm x Nt]
            RMSE_m = st_DNS{m}.RMSE_ave{s};

            U_ref = U_ref(:, 1:stride_r:end);   
            U_m   = U_m  (:, 1:stride_m:end);
        
        if RMSE_ref > 0
            RMSE_rel(im,s) = abs(RMSE_ref-RMSE_m)/abs(RMSE_ref);
        end


        % ---- Build coordinate matrices [x y] ----
        X_ref = [x_ref(:), y_ref(:)];   % [Nref x 2]
        X_m   = [x_m(:),   y_m(:)  ];   % [Nm   x 2]
        
        % ---- Compute pairwise distances between ref points and mesh-m points ----
        % D(i,j) = distance between point i in ref and point j in mesh m
        D = hypot(X_ref(:,1) - X_m(:,1).', X_ref(:,2) - X_m(:,2).');
        
        % For each ref point, find closest mesh-m point
        [dmin, idx_m_all] = min(D, [], 2);   % dmin: [Nref x 1], idx_m_all: [Nref x 1]
        
        % Keep only matches within tolerance
        Lia = dmin <= tol;
        
        idx_ref = find(Lia);          % indices in reference
        idx_m   = idx_m_all(Lia);     % corresponding indices in mesh m

        Ncommon(im,s) = numel(idx_ref);

        if Ncommon(im,s) == 0
            RMSE_space_time(im,s) = NaN;
            RMSE_t{im,s}         = nan(1, ts_base);
            continue
        end

        % ---- Extract velocity on common pixels ----
        Uref_common = U_ref(idx_ref, :);   % [Ncommon x Nt]
        Um_common   = U_m(idx_m,   :);     % [Ncommon x Nt]
        
        % ---- Space–time RMSE over all pixels and time ----
        diff_all = Um_common - Uref_common; % [Ncommon x Nt]
       
        RMSE_space_time(im,s) = sqrt(mean(diff_all(:).^2));
        % ---- Reference RMS over same pixels & times (for normalization) ----
        RMS_ref_all = sqrt(mean(Uref_common(:).^2));
        
        if RMS_ref_all > 0
            relErr_space_time(im,s) = RMSE_space_time(im,s) / RMS_ref_all;
        else
            relErr_space_time(im,s) = NaN;
        end
        
        % ---- Time-resolved RMSE(t) (space-averaged) ----
        diff_t = Um_common - Uref_common;                 % [Ncommon x Nt]
        RMSE_t{im,s} = sqrt(mean(diff_t.^2, 1));          % 1 x Nt
        
        % ---- Time-resolved reference RMS(t) ----
        RMS_ref_t = sqrt(mean(Uref_common.^2, 1));        % 1 x Nt
        
        % Avoid division by zero
        relErr_t{im,s} = nan(1, ts_base);
        nz = RMS_ref_t > 0;
        relErr_t{im,s}(nz) = RMSE_t{im,s}(nz) ./ RMS_ref_t(nz);
        
        % ---- Time-resolved L1 relative error (space-averaged) ----
        L1_num_t = mean(abs(diff_t),          1);   % 1 x Nt
        L1_den_t = mean(abs(Uref_common),     1);   % 1 x Nt
        
        relErr_L1_t{im,s} = nan(1, ts_base);
        nz_L1 = L1_den_t > 0;
        relErr_L1_t{im,s}(nz_L1) = L1_num_t(nz_L1) ./ L1_den_t(nz_L1); 
        u_rel(im,s) = max(abs(L1_num_t(nz_L1) ./ L1_den_t(nz_L1)));
        
        
        end
    end

    % ---------------- Pack output struct ----------------
    stats.nslices       = nslices;
    stats.Nt            = ts_base;

    stats.Ncommon           = Ncommon;
    stats.RMSE_space_time   = RMSE_space_time;
    stats.RMSE_t            = RMSE_t;
    
    stats.L2_u = relErr_space_time;
    stats.relErr_t          = relErr_t;
    stats.relErr_L1 = relErr_L1_t;
    stats.p_rel = rel_p;
    stats.dp = dp;
    stats.u_rel = u_rel;
    stats.RMSE_rel = RMSE_rel;

    
end