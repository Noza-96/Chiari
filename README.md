# Chiari Simulation Pipeline

This repository provides a step-by-step guide for creating computational simulations of cerebrospinal fluid (CSF) flow in Chiari Malformation patients. The pipeline integrates segmentation, geometry preparation, and numerical simulations to analyze CSF dynamics using a combination of advanced imaging and computational tools.

## Purpose

The pipeline facilitates the transformation of patient-specific imaging data into computational models for numerical simulations. This process includes segmentation of the CSF space, alignment of anatomical and flow-rate MRIs, computational geometry creation, meshing, and boundary condition integration for Ansys Fluent simulations.

<a id="Table_contents"></a>

## Table of Contents
1. [Segmentation](#Segmentation): Extract CSF anatomy from MRIs using ITK-Snap
2. [Alignment](#Alignment): Align anatomical segmentation to flow-rate MRI using Slicer.
3. [Smooth segmentation](#Smooth): Refine segmentation to a smooth 3D model using Fusion 360.
4. [Point cloud](#Point_cloud): Create a point cloud representation using Rhino.
5. [Computational geometry](#Computational_geometry): Build a simulation-ready geometry using SolidWorks.
6. [Meshing](#Ansys_mesh): Generate a computational mesh in Ansys.
7. [Inlet Boundary Conditions](#Inlet_BC): Process PC-MRI velocity data using MATLAB.
8. [Numerical simulations](#Numerical_simulations): Run simulations in Ansys Fluent to compute velocity and pressure fields.
9. [Post-processing](#Post-processing): Analyze results in MATLAB to extract insights like longitudinal impedance and velocity comparisons.

## Overview

For details on each step, refer to the [Table of Contents](#Table_contents). Ensure you have the necessary software installed, including ITK-Snap, Slicer, Fusion 360, Rhino, SolidWorks, Ansys, and MATLAB

## 1. Segmentation <a id="Segmentation"></a>

**Program**: iTK-Snap 

**Instructions**: 
1) Segmentation from the top segment of SAS to ~50 mm below. 
2) Make sure that bottom wall is below lower pc-MRI measurement.

**Output**: ID_Segmentation.nrrd and ID_non_smooth.stl 

[Back to top](#Table_contents)

## 2. Alignment anatomy to flow rate MRIs <a id="Alignment"></a>

**Program**: Slicer 

**Description**: The primary objective of this step is to use Slicer 3D to align the segmentation with the pcMRI measurements. Additional outcomes are a smoothed segmentation, automatically done by the program, as well as the extraction of the plane locations of the top and bottom pcMRI sites, needed later to perform the two cuts of the geometry.   

**Instructions**: 
1) Add ID_segmentation.nrrd of anatomy and .dcm of all flow rate measurements to SLICER. 
2) Apply a linear transformation to anatomy MRI till there is alignment with dicoms.

 **Output**: ID_transformed_segmentation.nrrd and ID_transformed.stl 

<details>
  <summary> Step-by-Step:</summary>

1) add data
![alt text](screenshots/1_add_data.png)

2) load flow as sequences and anatomy as segmentation
![alt text](screenshots/2_load_sequences_segmentation.png)

3) load segmentation as volume, this allows for the linear transformation
![alt text](screenshots/3_load_nrddsegmentation_as_volume.png)

4) center 3D view
![alt text](screenshots/4_center_3D_view.png) 

5) rotate to volume plane
![alt text](screenshots/5_rotate_to_volume_plane.png) 

6) reset field of view, assign each window to a different view (c1c2, ...) and unable  3D view (open eye)
![alt text](screenshots/6_reset_field_of_view.png) 

7) go to segmentations
![alt text](screenshots/7_go_to_segmentations.png) 

8) change to desired opacity
![alt text](screenshots/8_change_opacity.png) 

9) go to transforms
![alt text](screenshots/9_go_to_transforms.png) 

10) create new linear transform
![alt text](screenshots/10_create_new_linear_transform.png) 

11) transform both segmentation and volume
![alt text](screenshots/11_transformed_both_nrrd_segmentaiton_and_volume.png) 

12) after flow measurements are aligned with anatomy, go to resample image
![alt text](screenshots/12_go_to_resample_image.png) 

13) in inputs, image to wrap volume
![alt text](screenshots/13_image_to_warp_volume_nrrd.png) 

14) create new volume as ID_transformed_segmentation
![alt text](screenshots/14_name_output_image.png) 

15) select the linear transformation
![alt text](screenshots/15_select_your_linear_transform.png) 

16) apply linear transformation
![alt text](screenshots/16_apply.png) 

17) go to data
![alt text](screenshots/17_go_to_data.png) 

18) export to file
![alt text](screenshots/18_export_to_file.png) 

19) save slicer 3D session with all changes as ID_slicer, for future use

20) if you want to obtain the plane defined by a dicom to do a subsequent cut of the geometry, open the Python Interactor in Slicer (```Ctrl + 3```) and run the code, using **yellow, green, or red**:  -->

```
import platform
import os

hostname = platform.node()
if hostname == 'Guillermos-MacBook-Pro.local':
    chiari_path = '/Users/noza/Documents/chiari'
else:
    raise NotImplementedError
    chiari_path = '' # TODO: implement later

exec(open(os.path.join(chiari_path, "git-chiari/slicer3D-code/slicer_clip_planes.py")).read())

```



**Next two steps (20 and 21) are only for visualization!**

20) change background color
![alt text](screenshots/19_change_background_color.png) 

21) spin 3D view
![alt text](screenshots/20_spin_3D_view.png)


**Save as stl:**

21) load ID_transformed_segmentation.nrrd
![alt text](screenshots/stl_1_load_nrrd.png) 

22) go to data
![alt text](screenshots/stl_2_go_to_data.png)

23) export visible segments to models
![alt text](screenshots/stl_3_export_visible_segments.png)

24) export to file 
![alt text](screenshots/stl_4_export_to_file.png)

25) save as ID_transformed.stl
![alt text](screenshots/stl_5_save_as_stl.png)

**Clip segmentation between in-plane measurements:**

26) go to Segmentations, in the bottom select export models, make segmentation unvisible
![alt text](screenshots/clip_1.png)

27) go to Models, change color to differentiate from segmentation
![alt text](screenshots/clip_3.png)

28) clip selected model, selecting the options at the bottom of the figure
![alt text](screenshots/clip_5.png)

29) go to Data, save as ID_segmentation.stl
![alt text](screenshots/clip_6.png)

</details>

[Back to top](#Table_contents)

<!-- ## 3. Smooth segmentation <a id="Smooth"></a>

**Program**:  Fusion 360

**Instructions**: Smooth segmentation

**Output**: ID_smooth.stl

[Back to top](#Table_contents) -->



## 3. Point cloud <a id="Point_cloud"></a>

**Program**:  Rhino 8

**Instructions**: Transform ID_smooth.stl to point cloud. 

**Output**: ID_cloud.3dm

[Back to top](#Table_contents)

## 5. Computational geometry <a id="Computational_geometry"></a>
**Program**: SolidWorks 

**Instructions**: 
1) Open ID_cloud.3dm in Solidworks to create a readable geometry to Ansys.
2) Make two cuts in the XY-plane at the top and bottom surfaces. 

**Output**: ID_ansys.STEP

[Back to top](#Table_contents)


## 6. Ansys Mesh <a id="Ansys_mesh"></a>
**Program**: Ansys

**Outputs**: 
1) Ansys mesh to use in numerical simulations.
2) .prof of the lower boundary. 

[Back to top](#Table_contents)

## 7. Velocities from PC MRI measurements <a id="Inlet_BC"></a>

**Program**:  Matlab

**Instructions**: 
1) Use Will's code to obtain flow rate and velocities from PC MRI measurements. 
2) Transformation from image domain to computational domain. 
3) Fourier transform to compute velocity field.

**Output**: .prof for 100 instants of time to add in Ansys as inlet boundary condition. 

[Back to top](#Table_contents)

## 8. Numerical simulations <a id="Numerical_simulations"></a>

**Program**: Ansys Fluent

**Outputs**: 
1) Pressure drop in 25 mm section (used to calculate longitudinal impedance).
2) Time-dependent velocity field at the measurement locations.  

[Back to top](#Table_contents)

## 9. Post-processing  <a id="Post-processing"></a>

**Program**:  Matlab

**Output**: 
1) longitudinal impedance.
2) Comparison measured velocity to calculated velocity.

[Back to top](#Table_contents)