# Chiari Simulation Pipeline

The pipeline facilitates the transformation of patient-specific imaging data into computational models for numerical simulations. This process includes segmentation of the CSF space, velocity processing from pc-MRI data and registration to segmentation, computational geometry creation, meshing, and boundary condition integration for Ansys Fluent simulations.

## Installation & Setup Guide <a id="Installation"></a>

This project uses MATLAB, Python, 3D Slicer, Spinal Cord Toolbox, and auxiliary imaging tools.  
Follow the steps below to prepare your system before running the Chiari Simulation Pipeline.

--------------------------------------------------------------------

1. MATLAB (R2023a)

Download:
https://www.mathworks.com/products/matlab/student.html

Required Toolbox:
- Image Processing Toolbox
- Medical Imaging Toolbox

--------------------------------------------------------------------

2. 3D Slicer (v5.8.1)

Download:
https://www.slicer.org/

Used for segmentation, anatomical alignment, and MRI visualization.

--------------------------------------------------------------------

3. Python (3.11.12) + Anaconda

Install Python:
https://www.python.org/downloads/

Install Anaconda:
https://www.anaconda.com/download

Once you clone the repository, on git-chiari folder from terminal run:

    conda env create -f environment.yml

    conda activate chiari

This installs all Python dependencies from environment.yml.

--------------------------------------------------------------------

4. dcm2niix (DICOM to NIfTI converter)

Download (version 11-December-2024):
https://github.com/rordenlab/dcm2niix/releases

Verify installation:

    dcm2niix -h

If not found, add the installation folder to your PATH.

--------------------------------------------------------------------

5. Spinal Cord Toolbox (SCT) + DeepSeg

Installation instructions:
https://spinalcordtoolbox.com/user_section/installation/windows.html

Check installed DeepSeg tasks:

    sct_deepseg

If SCT is older than version 7.0, required tasks:
- seg_sc_contrast_agnostic
- canal_t2w

If SCT version is 7.0 or newer, required tasks:
- spinalcord
- sc_canal_t2

Install a missing task (example):

    sct_deepseg sc_canal_t2 -install

--------------------------------------------------------------------

6. ANSYS Fluent

Version: 2024 R1  
Download:
https://www.ansys.com/academic/students/ansys-student
