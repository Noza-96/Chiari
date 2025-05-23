from qt import QInputDialog, QMessageBox
import platform
import os
import SegmentEditorEffects
import slicer
import vtk

def segmentation_2D_slices(segmentation_node, volume_node, segmentation_2D_path):
    # Clone input volume for output
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

    # Return output volume node
    return output_volume

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
registration_path = os.path.join(chiari_path, "computations", "pc-mri", subject, "registration");
segmentation_2D_path = os.path.join(registration_path, "2D-segmentation");
registration_input = os.path.join(registration_path, "input-velocity");
registration_output = os.path.join(registration_path, "output-velocity");

# load segmentation as stl and transform to segmentation
segmentation_node = load_stl_as_segmentation(os.path.join(stl_path, 'segmentation.stl'))

# Obtain list of locations
files = os.listdir(segmentation_2D_path)
slice_locations = [f.split('_roi.nrrd')[0] for f in files if f.endswith('_roi.nrrd')]
print(slice_locations)


for i in range(len(slice_locations)):
    pcmri_node = slicer.util.loadVolume(os.path.join(segmentation_2D_path, slice_locations[i] + "_roi.nrrd"))
    pcmri_node.SetName(slice_locations[i])

    segmentation_2D_node = segmentation_2D_slices(segmentation_node, pcmri_node, segmentation_2D_path)

    # Remove the pcmri_node from the scene
    slicer.mrmlScene.RemoveNode(pcmri_node)

