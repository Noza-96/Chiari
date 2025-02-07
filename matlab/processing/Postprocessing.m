%Obtain Coordinates of velocity measurements and relative location wrt to
%segmentation
clear; close all;
addpath('Functions/');
addpath('Functions/Others/')

% Choose subject
subject = "s101";
session = 'before';
case_name = "c2"; %c1 for bottom inlet velocity and top zero pressure, c2 for two inlet velocities and permeable cord
mesh_size = 0.001;


case_report = case_name+"_dx"+formatDecimal(DNS.mesh_size); 

% Define MRI data path
load(fullfile("../../../computations", "pc-mri", subject, 'flow', session,"mat","03-apply_roi_compute_Q.mat"));

% read ansys reports and save solution in .mat file
read_ansys_reports(cas, dat_PC, case_report) % last number is in case output is not available

load(fullfile(cas.dirmat, "pcmri_vel.mat"), 'pcmri');
load(fullfile(cas.dirmat, "DNS_"+case_report+".mat"), 'DNS');
%% 2. Create 3D animations with velocity results into spinal canal geometry
animation_3D(cas, dat_PC, DNS)

%% 3. Longitudinal impedance - Pressure drop and Flow rate
longitudinal_impedance(cas, DNS)

%% 4. Comparison PC-MRI with Ansys solution -- Animation
comparison_results(cas, pcmri, "c1", "c2")

%% flow rates 
figure
tiledlayout(3,1)
nexttile
flow_rate(DNS.out.q_bottom* 1e6, 0)
nexttile
flow_rate(DNS.out.q_top* 1e6, 0)
nexttile
flow_rate(DNS.out.q_cord* 1e6, 0)
%% Create animations ANSYS simulations - uniform velocity field
