# Chiari

# TODO: re-write these instructions with the screenshots/videos

# 1. Alignment anatomy to flow rate MRIs
**Program**: Slicer 


## Instructions: 
1) Add ID_segmentation.nrrd of anatomy and .dcm of all flow rate measurements to SLICER. 
2) Apply a linear transformation to anatomy MRI till there is alignment with dicoms.

## Step-by-Step:

1) add data
![alt text](screenshots/1_add_data.png)

2) load flow as sequences and anatomy as segmentation
![111](screenshots/2_load_sequences_segmentation.png)

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

14) save output image as ID_transformed_segmentation
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

20) if you want to obtain the plane defined by a dicom to do a subsequent cut of the geometry, open the Python Interactor in Slicer (```Ctrl + 3```) and run the code, using **yellow, green, or red**: 

```
# Get the Yellow slice node (for c3-c4 view)
sliceNode = slicer.mrmlScene.GetNodeByID("vtkMRMLSliceNodeYellow")

# Get the SliceToRAS transform matrix (mapping slice coordinates to RAS coordinates)
sliceToRAS = sliceNode.GetSliceToRAS()

# Get the origin (position) of the slice (translation part of the transformation matrix)
origin = sliceToRAS.GetElement(0, 3), sliceToRAS.GetElement(1, 3), sliceToRAS.GetElement(2, 3)

# Get the normal vector (orientation of the slice)
normal = sliceToRAS.MultiplyPoint((0, 0, 1, 0))[:3]  # This applies the slice's orientation in RAS coordinates

# Output the results
print("Origin (Position):", origin)  # This is the position of the plane
print("Normal Vector:", normal)      # This is the direction of the plane

# Optionally, save the plane parameters to a text file for later use
with open("plane_info.txt", "w") as f:
    f.write(f"Origin: {origin}\n")
    f.write(f"Normal: {normal}\n")

print("Plane information saved to plane_info.txt")=
```


**Next is only for visualization!**

19) change background color
![alt text](screenshots/19_change_background_color.png) 

20) spin 3D view
![alt text](screenshots/20_spin_3D_view.png)

 **Output**: ID_transformed_segmentation.nrrd
Linear transformation applied to the anatomy

# 2. Segmentation
**Program**: iTK-Snap 

**Instructions**: 
1) Segmentation from the top segment of SAS to ~50 mm below. 
2) Make sure wall bottom surface 
is perpendicular to the to the XY-plane. 

**Output**: ID_Segmentation.nrrd and ID_non_smooth.stl 

# 3. Smooth segmentation
**Program**:  Fusion 360

**Instructions**: Smooth segmentation

**Output**: ID_smooth.stl

# 4. Point cloud
**Program**:  Rhino 8

**Instructions**: Transform ID_smooth.stl to point cloud. 

**Output**: ID_cloud.3dm

# 5. Computational geometry
**Program**: SolidWorks 

**Instructions**: 
1) Open ID_cloud.3dm in Solidworks to create a readable geometry to Ansys.
2) Make two cuts in the XY-plane at the top and bottom surfaces. 

**Output**: ID_ansys.STEP

# 6. Ansys Mesh
**Program**: Ansys

**Outputs**: 
1) Ansys mesh to use in numerical simulations.
2) .prof of the lower boundary. 

# 7. Inlet BC from PC MRI measurements
**Program**:  Matlab

**Instructions**: 
1) Use Will's code to obtain flow rate and velocities from PC MRI measurements. 
2) Transformation from image domain to computational domain. 
3) Fourier transform to compute velocity field.

**Output**: .prof for 100 instants of time to add in Ansys as inlet boundary condition. 

# 8. Numerical simulations
**Program**: Ansys Fluent
**Outputs**: 
1) Pressure drop in 25 mm section (used to calculate longitudinal impedance).
2) Time-dependent velocity field at the measurement locations.  

# 9. Post-processing 
**Program**:  Matlab

**Output**: 
1) longitudinal impedance.
2) Comparison measured velocity to calculated velocity.

