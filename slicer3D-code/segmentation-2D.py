from qt import QInputDialog, QMessageBox
import platform
import os
import SegmentEditorEffects
import slicer
import vtk
import ants
import trimesh
import numpy as np
from PIL import Image, ImageDraw


def register_velocity_image(segmentation_2d_file, pcmri_roi_file, pcmri_velocity_input, output_path):
    """
    Register a 2D velocity image to a fixed anatomical ROI mask using ANTs in 2D.
    
    Parameters:
        segmentation_2d_file (str): Path to fixed segmentation mask (.nrrd from STL).
        pcmri_roi_file (str): Path to moving ROI segmentation (.nrrd).
        pcmri_velocity_input (str): Path to the moving velocity image (.nrrd).
        pcmri_velocity_output (str): Path to save the registered velocity image.
    
    Returns:
        ants.ANTsImage: The registered velocity image.
    """
    # Read input images
    fixed_mask = ants.image_read(segmentation_2d_file)
    moving_mask = ants.image_read(pcmri_roi_file)
    moving_image = ants.image_read(pcmri_velocity_input)

    # Collapse 3D -> 2D
    fixed_mask_2d = collapse_to_2d(fixed_mask)
    moving_mask_2d = collapse_to_2d(moving_mask)
    moving_image_2d = collapse_to_2d(moving_image)

    # 2D registration
    reg = ants.registration(fixed=fixed_mask_2d,
                            moving=moving_mask_2d,
                            type_of_transform='SyNAggro',
                            dimensionality=2,
                            verbose=True)

    # Apply transformation to velocity image
    velocity_image_registered = ants.apply_transforms(
        fixed=fixed_mask_2d,
        moving=moving_image_2d,
        transformlist=reg['fwdtransforms']
    )

    # Convert back to 3D (singleton z-dim)
    arr3d = velocity_image_registered.numpy()[:, :, np.newaxis]
    velocity_image_aligned = ants.from_numpy(
        arr3d,
        origin=fixed_mask.origin,
        spacing=fixed_mask.spacing,
        direction=fixed_mask.direction
    )

    # Save result
    ants.image_write(velocity_image_aligned, output_path)
    print(f"✅ Registered velocity image saved to: {output_path}")

# Convert 3D image (with singleton z) to 2D
def collapse_to_2d(image):
    arr = image.numpy()
    arr2d = arr[:, :, 0]  # get the only slice
    return ants.from_numpy(arr2d, spacing=image.spacing[:2], origin=image.origin[:2], direction=image.direction[:2,:2])

def segmentation_2D_slices(segmentation_node, roi_path, segmentation_2D_path):
    # Clone input volume for output
    volume_node = slicer.util.loadVolume(roi_path)
    volumes_logic = slicer.modules.volumes.logic()
    output_volume = volumes_logic.CloneVolume(slicer.mrmlScene, volume_node, volume_node.GetName() + "_segmentation")

    # Get segment ID
    segment_id = segmentation_node.GetSegmentation().GetNthSegmentID(0)

    # Fill INSIDE the segment with 1
    SegmentEditorEffects.SegmentEditorMaskVolumeEffect.maskVolumeWithSegment(
        segmentation_node,
        segment_id,
        "FILL_INSIDE",
        [1],
        output_volume,
        output_volume,
        [0]*6
    )

    # Fill OUTSIDE the segment with 0
    SegmentEditorEffects.SegmentEditorMaskVolumeEffect.maskVolumeWithSegment(
        segmentation_node,
        segment_id,
        "FILL_OUTSIDE",
        [0],
        output_volume,
        output_volume,
        [0]*6
    )

    # Save final NRRD
    slicer.util.saveNode(output_volume, segmentation_2D_path)
    print(f"✅ Saved masked volume (2D segmentation) to: {segmentation_2D_path}")
    # Remove all nodes from scene
    slicer.mrmlScene.RemoveNode(volume_node)
    slicer.mrmlScene.RemoveNode(output_volume)


def count_files_starting_with(location, registration_input):
    return sum(
        fname.startswith(location)
        for fname in os.listdir(registration_input)
        if os.path.isfile(os.path.join(registration_input, fname))
    )

# Function to display the segmentation in 3D
def display_segmentation_3D(segmentation_node, opacity2D=0.4):
    segmentation_node.CreateClosedSurfaceRepresentation()
    segmentation_display_node = segmentation_node.GetDisplayNode()
    segmentation_display_node.SetVisibility3D(True)
    segmentation_display_node.SetOpacity3D(0.6)
    segmentation_display_node.SetOpacity2DFill(opacity2D)
    segmentation_display_node.SetOpacity2DOutline(opacity2D)

def load_stl_as_segmentation(stl_file_path):
    """
    Load an STL file as a segmentation node in Slicer and display it in 3D.

    Parameters:
    - stl_file_path: full path to the .stl file
    - segmentation_name: name to assign to the segmentation node

    Returns:
    - segmentation_node: the created vtkMRMLSegmentationNode
    """
    # Load STL as model
    model_node = slicer.util.loadModel(stl_file_path)
    model_node.SetName("del_segmentation")

    # Create and import to segmentation
    segmentation_node = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLSegmentationNode', "segmentation")
    slicer.modules.segmentations.logic().ImportModelToSegmentationNode(model_node, segmentation_node)

    # Display segmentation in 3D
    display_segmentation_3D(segmentation_node)

    # Clean up: remove model node from scene
    slicer.mrmlScene.RemoveNode(model_node)

    # Ensure display nodes exist
    segmentation_node.CreateDefaultDisplayNodes()

    return segmentation_node


subject = sys.argv[1]
nii_filename = sys.argv[2]
chiari_path = sys.argv[3]

segmentation_path = os.path.join(chiari_path, "computations", "segmentation", subject)
stl_path = os.path.join(segmentation_path, "stl")

# define paths
registration_path = os.path.join(chiari_path, "computations", "pc-mri", subject, "registration")
segmentation_2D_folder = os.path.join(registration_path, "2D-segmentation")
registration_input_folder = os.path.join(registration_path, "input-velocity")
registration_output_folder = os.path.join(registration_path, "output-velocity")

# load segmentation as stl and transform to segmentation
segmentation_node = load_stl_as_segmentation(os.path.join(stl_path, 'segmentation.stl'))

# Obtain list of locations
files = os.listdir(segmentation_2D_folder)
slice_locations = [f.split('_roi.nrrd')[0] for f in files if f.endswith('_roi.nrrd')]
print(slice_locations)


# Define output file path (include name)

for i in range(len(slice_locations)):
    location = slice_locations[i]
    segmentation_2D_path = os.path.join(segmentation_2D_folder, location + "_segmentation.nrrd")
    pcmri_roi_path = os.path.join(segmentation_2D_folder, location + "_roi.nrrd")

    # save 2D segmentation
    segmentation_2D_slices(segmentation_node, pcmri_roi_path, segmentation_2D_path)

    # number N of time frames
    Nt = count_files_starting_with(location, registration_input_folder)

    # Register velocity images
    for n in range(1, Nt + 1):
        pcmri_velocity_in_path = os.path.join(registration_input_folder, location + "_u_" + str(n) + ".nrrd")
        pcmri_velocity_out_path = os.path.join(registration_output_folder, location + "_u_" + str(n) + ".nrrd")
        register_velocity_image(segmentation_2D_path, pcmri_roi_path, pcmri_velocity_in_path, pcmri_velocity_out_path)


