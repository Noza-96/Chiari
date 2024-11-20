# Chiari
# 1. Alignment anatomy to flow rate MRIs
**Program**: Slicer 

**Instructions**: 
1) Add ID_segmentation.nrrd of anatomy and .dcm of all flow rate measurements to SLICER. 
2) Apply a linear transformation to anatomy MRI till there is alignment with dicoms.

**Output**: ID_Transformed_Anatomy.nrrd
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

