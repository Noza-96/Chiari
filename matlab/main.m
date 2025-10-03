% Add functions
clear; close all; clc;
addpath('pc-MRI/');
addpath('processing/');
addpath('processing/Functions/');
addpath('processing/Functions/Others/');

subject = "s5";

%% 1) Organize DICOM data
% out: list DICOMs and organize into flow and anatomy 
organize_DICOMS(subject)

%% 2) Segmentation CSF space
% out: automatic + manual segmentation -> .STL file
run_segmentation(subject)

%% 3) Alignment velocity measurements to segmentation
% out: translation velocity DICOMs to adjucts to segmentation
alignment_MRI(subject)
%% 4) PC-MRI measurements
% out: flow and tissue metrics extracted from PC-MRI measurements

%% 6) Define geometry in SpaceClaim
% out: computational domain

%% 6) Mesh - create case
% out: mesh and case for ANSYS Fluent simulations

%% 5) ANSYS simulations
% out: 

%% 6) Post-processing
% out: computational domain