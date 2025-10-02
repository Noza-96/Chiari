from qt import QInputDialog, QMessageBox
import platform
import os
import SegmentEditorEffects
import slicer
import vtk

# Suppress VTK warnings and errors
vtk.vtkObject.GlobalWarningDisplayOff()

# Clear the MRML scene to delete all loaded data
slicer.mrmlScene.Clear(0)


def segmentation_2D_slices(segmentation_node, volume_node, segmentation_2D_path):

    # Clone input volume for output
    volumes_logic = slicer.modules.volumes.logic()
    output_volume = volumes_logic.CloneVolume(slicer.mrmlScene, volume_node, volume_node.GetName() + "_segmentation")

    # Get segment ID
    segment_id = segmentation_node.GetSegmentation().GetNthSegmentID(0)

    # Fill INSIDE the segment with 0
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

    # Remove volume from scene
    slicer.mrmlScene.RemoveNode(output_volume)

def get_volumes_sorted_by_z():
    volume_nodes_with_z = []

    for node in slicer.util.getNodesByClass("vtkMRMLScalarVolumeNode"):
        if node.GetName() == "anatomy":
            continue

        ijk_to_ras_matrix = vtk.vtkMatrix4x4()
        node.GetIJKToRASMatrix(ijk_to_ras_matrix)

        z_coordinate = ijk_to_ras_matrix.GetElement(2, 3)
        volume_nodes_with_z.append((node, z_coordinate))

    # Sort in descending order (highest z first)
    volume_nodes_with_z.sort(key=lambda x: x[1], reverse=True)

    return [node for node, _ in volume_nodes_with_z]

# Assign the volume nodes to specific slice views
def assign_to_slices(sorted_volumes, slice_views):


    layout_manager = slicer.app.layoutManager()
    num_pairs = min(len(sorted_volumes), len(slice_views))

    for i in range(num_pairs):
        volume_node = sorted_volumes[i]
        view_name = slice_views[i]

        slice_widget = layout_manager.sliceWidget(view_name)
        if slice_widget and volume_node is not None:
            composite_node = slice_widget.sliceLogic().GetSliceCompositeNode()
            composite_node.SetBackgroundVolumeID(volume_node.GetID())
        else:
            print(f"Skipping slice view '{view_name}' or volume index {i}")

    # Assign 'anatomy' to the last slice view
    anatomy_node = slicer.util.getNode("anatomy")
    last_view = slice_views[-1]
    composite_node = layout_manager.sliceWidget(last_view).sliceLogic().GetSliceCompositeNode()
    composite_node.SetBackgroundVolumeID(anatomy_node.GetID())

def import_and_load_dicom(pcMRI_path):
    # Open the DICOM module to initialize the database
    slicer.util.selectModule('DICOM')

    # Ensure the DICOM database is open
    if not slicer.dicomDatabase.isOpen:
        dicomDatabaseDir = slicer.app.temporaryPath + "/DICOM"
        slicer.dicomDatabase.openDatabase(dicomDatabaseDir)

    # Import the DICOM files using the existing database (without using TemporaryDICOMDatabase)
    DICOMUtils.importDicom(pcMRI_path, slicer.dicomDatabase)
    slicer.app.processEvents()

    print(f"Successfully imported all DICOM files from: {pcMRI_path}")

def maximize_slice_view(view_name):
    layout_node = slicer.app.applicationLogic().GetLayoutNode()

    layout_map = {
        "Red": slicer.vtkMRMLLayoutNode.SlicerLayoutOneUpRedSliceView,
        "Yellow": slicer.vtkMRMLLayoutNode.SlicerLayoutOneUpYellowSliceView,
        "Green": slicer.vtkMRMLLayoutNode.SlicerLayoutOneUpGreenSliceView
    }

    if view_name in layout_map:
        layout_node.SetViewArrangement(layout_map[view_name])
    else:
        print(f"Slice view '{view_name}' cannot be maximized (not supported).")

# Function to adjust the slice views
def adjust_slice_views(slice_views):
    layout_manager = slicer.app.layoutManager()
    for view in slice_views:
        # Get the slice widget for the current view
        slice_view = layout_manager.sliceWidget(view)
        # Get the slice logic for the current view
        slice_logic = slice_view.sliceLogic()
        slice_node = slice_logic.GetSliceNode()
        # Set the orientation to axial
        slice_node.SetOrientation("Axial")
        # Reset the view by fitting it to the entire scene
        slice_logic.FitSliceToAll()
        # Rotate the slice to match the lowest volume axes
        slice_logic.RotateSliceToLowestVolumeAxes()
        # Make visible in 3D
        current_visibility = slice_node.GetSliceVisible()
        slice_node.SetSliceVisible(not current_visibility)
        # Center the view in the 3D view
        threeD_view = layout_manager.threeDWidget(0).threeDView()
        threeD_view.resetFocalPoint()
        view_node = threeD_view.mrmlViewNode()
        view_node.SetBoxVisible(False)

# Function to display the segmentation in 3D
def display_segmentation_3D(segmentation_node, opacity2D=0.4):
    segmentation_node.CreateClosedSurfaceRepresentation()
    segmentation_display_node = segmentation_node.GetDisplayNode()
    segmentation_display_node.SetVisibility3D(True)
    segmentation_display_node.SetOpacity3D(0.6)
    segmentation_display_node.SetOpacity2DFill(opacity2D)
    segmentation_display_node.SetOpacity2DOutline(opacity2D)

def get_slice_labels(flow_path):
    """
    Return list of slice labels ['FM','C1C2',...] from subfolders named 'z#-LABEL'.
    """
    import os, re
    labels = []
    for name in os.listdir(flow_path):
        if os.path.isdir(os.path.join(flow_path, name)):
            m = re.match(r"^z\d+-(.+)$", name, re.IGNORECASE)
            if m:
                labels.append(m.group(1))
    return labels

def save_transformation_matrix(transform_node, save_path):
    if not transform_node:
        print("Error: No transform node found.")
        return

    # Get the transformation matrix
    matrix = vtk.vtkMatrix4x4()
    transform_node.GetMatrixTransformToParent(matrix)

    # Invert the matrix - because transformation was applied to segmentation 
    inverse_matrix = vtk.vtkMatrix4x4()
    vtk.vtkMatrix4x4.Invert(matrix, inverse_matrix)

    # Save the inverse matrix to file
    with open(save_path, "w") as f:
        for row in range(4):
            f.write(" ".join(f"{inverse_matrix.GetElement(row, col):.2f}" for col in range(4)) + "\n")



# INPUTS 
pid = sys.argv[1]
chiari_path = sys.argv[2]


main_path =  os.path.join(chiari_path, f'computations/segmentation/{pid}')
segmentation_path = os.path.join(main_path, 'stl')
pcMRI_path = os.path.join(main_path, "pcMRI")
transformation_path = os.path.join(main_path, 'transformation')

flow_path = os.path.join(chiari_path, f'patient-data/{pid}/flow')


# load anatomy
volume_node = slicer.util.loadVolume(os.path.join(segmentation_path, "anatomy.nrrd"))
volume_node.SetName("anatomy")

# Convert stl as model and transform it to segmentation node
model_node = slicer.util.loadModel(os.path.join(segmentation_path, 'segmentation.stl'))
model_node.SetName("segmentation")
segmentation_node = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLSegmentationNode', 'segmentation')
slicer.modules.segmentations.logic().ImportModelToSegmentationNode(model_node, segmentation_node)
display_segmentation_3D(segmentation_node)
slicer.mrmlScene.RemoveNode(model_node)
segmentation_node.CreateDefaultDisplayNodes()

import_and_load_dicom(flow_path)

# --- Extract slice labels from z#-LABEL folder names ---
id_slices = get_slice_labels(flow_path)
print("id_slices:", id_slices)


# Get all .nrrd files in the directory pcMRI and load them as Sequence
files = os.listdir(pcMRI_path)
nrrd_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]
for file_name in nrrd_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadSequence(file_path)
    
# Adjust setup slicer 3D to 3x2
slicer.app.layoutManager().setLayout(slicer.vtkMRMLLayoutNode.SlicerLayoutFourUpView)
slice_views = ["Red",  "Green", "Yellow", "Slice4"]

# Sort the volumes by z-coordinate
sorted_volumes = get_volumes_sorted_by_z()

    
# Assign the sorted volumes to the slice views
assign_to_slices(sorted_volumes, slice_views)

# Adjust the slice views
adjust_slice_views(slice_views)


# rename sliced volumes
for label, node in zip(id_slices, sorted_volumes):
    node.SetName(label)

# Iterate over all volume nodes in the scene
for k in range(len(sorted_volumes)):
    pcmri_node = sorted_volumes[k]
    set_manual = True
    pcmri_transformation = os.path.join(transformation_path, pcmri_node.GetName() + "_transformation.txt")
    segmentation_2D_path = os.path.join(segmentation_path, '2D-segmentation', pcmri_node.GetName() + "_segmentation.nrrd")
    # Apply a linear transformation to the pc-mri slices
    if os.path.exists(pcmri_transformation):
        response = QMessageBox.question(None, 'Load Existing Transformation', pcmri_node.GetName() + ': apply existing transformation?', QMessageBox.No | QMessageBox.Yes, QMessageBox.Yes )
        if response == QMessageBox.Yes:
            # Load the 4x4 transformation matrix from the txt file
            matrix = vtk.vtkMatrix4x4()
            with open(pcmri_transformation, 'r') as f:
                for i in range(4):
                    values = list(map(float, f.readline().split()))
                    for j in range(4):
                        matrix.SetElement(i, j, values[j])

            # Create and populate a VTK transform
            vtk_transform = vtk.vtkTransform()
            vtk_transform.SetMatrix(matrix)

            # Create a Slicer transform node and assign the transform
            transform_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLTransformNode", "LoadedTransform")
            transform_node.SetAndObserveTransformToParent(vtk_transform)

            # Apply the transform to the segmentation node
            pcmri_node.SetAndObserveTransformNodeID(transform_node.GetID())

            # Harden the transform to bake it into the volume
            slicer.vtkSlicerTransformLogic().hardenTransform(pcmri_node)

            # Clean up: remove the temporary transform node
            slicer.mrmlScene.RemoveNode(transform_node)

            adjust_slice_views(slice_views)
            set_manual = False

    if set_manual:
        # 2. M  anually adjust the transformation if desired
        response = QMessageBox.question(None, 'Manual Linear Transformation', pcmri_node.GetName() + ': create new transformation?', QMessageBox.No | QMessageBox.Yes, QMessageBox.Yes)
        if response == QMessageBox.Yes:
            # Open the GUI Module Transforms on Slicer3D
            slicer.util.selectModule('Transforms')
            # Create a new transform node
            transform_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLTransformNode", "ManualTransform")
            # Create a vtkTransform object
            vtk_transform = vtk.vtkTransform()
            # TODO: set the Active Transform to the new transform node
            # Apply the transform to segmentation node
            segmentation_node.SetAndObserveTransformNodeID(transform_node.GetID())
            segmentation_display_node = segmentation_node.GetDisplayNode()
            display_segmentation_3D(segmentation_node, opacity2D=0.4)

            while True:
                user_input = input('Type "ok" when you have finished the manual transformation: ')
                if user_input.lower() == 'ok':

                    response = QMessageBox.question(None, 'Export pcmri', 'Do you want to save results?', QMessageBox.No | QMessageBox.Yes, QMessageBox.Yes)
                    if response == QMessageBox.Yes:
                        if not os.path.exists(transformation_path):
                            os.makedirs(transformation_path)

                        # Save transformation matrix
                        save_transformation_matrix(transform_node, transformation_path)
                        slicer.mrmlScene.RemoveNode(transform_node)

                        # Output the results
                        print("transformation matrix saved to: " + transformation_path)
                    break
    if not os.path.exists(segmentation_2D_path):

        segmentation_2D_slices(segmentation_node, pcmri_node, segmentation_2D_path)
        # slicer.mrmlScene.RemoveNode(segmentation_node)
        

    