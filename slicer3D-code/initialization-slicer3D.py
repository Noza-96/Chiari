from qt import QInputDialog, QMessageBox
import platform
import os
import slicer
import vtk

# Suppress VTK warnings and errors
vtk.vtkObject.GlobalWarningDisplayOff()

# Clear the MRML scene to delete all loaded data
slicer.mrmlScene.Clear(0)

# Function to get the volume nodes with the maximum, minimum, and mid-z origins 
def get_volumes_with_extreme_and_mid_z():
    max_z = float('-inf')
    min_z = float('inf')
    volume_with_max_z = None
    volume_with_min_z = None
    volume_with_mid_z = None

    # List to store all volumes with their z-coordinates
    volume_nodes_with_z = []

    # Iterate over all volume nodes in the scene
    for node in slicer.util.getNodesByClass("vtkMRMLScalarVolumeNode"):
        # Skip the transformed_segmentation_v volume
        if node.GetName() == "transformed_segmentation_v":
            continue

        # Get the IJK-to-RAS transformation matrix
        ijk_to_ras_matrix = vtk.vtkMatrix4x4()
        node.GetIJKToRASMatrix(ijk_to_ras_matrix)

        # Extract the z-coordinate of the origin (last column of the matrix)
        z_coordinate = ijk_to_ras_matrix.GetElement(2, 3)

        # Store the volume node and its z-coordinate
        volume_nodes_with_z.append((node, z_coordinate))

        # Check for max z
        if z_coordinate > max_z:
            max_z = z_coordinate
            volume_with_max_z = node

        # Check for min z
        if z_coordinate < min_z:
            min_z = z_coordinate
            volume_with_min_z = node

    # Calculate the mid-z coordinate
    mid_z = (max_z + min_z) / 2

    # Find the volume closest to the mid-z
    closest_z_diff = float('inf')
    for node, z_coordinate in volume_nodes_with_z:
        z_diff = abs(z_coordinate - mid_z)
        if z_diff < closest_z_diff:
            closest_z_diff = z_diff
            volume_with_mid_z = node

    return volume_with_max_z, volume_with_min_z, volume_with_mid_z

# Assign the volume nodes to specific slice views
def assign_to_slices(volume_max_z, volume_min_z, volume_mid_z):
    if volume_min_z is not None:
        slicer.app.layoutManager().sliceWidget("Yellow").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_min_z.GetID())
    else:
        print("No volume node found for minimum z.")

    if volume_max_z is not None:
        slicer.app.layoutManager().sliceWidget("Red").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_max_z.GetID())
    else:
        print("No volume node found for maximum z.")

    if volume_mid_z is not None:
        slicer.app.layoutManager().sliceWidget("Green").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_mid_z.GetID())
    else:
        print("No volume node found for mid z.")

# Function to get the Patient ID using a dialog box
def get_patient_id():
    result = QInputDialog.getText(None, "Patient ID", "Enter the Patient ID:")
    if isinstance(result, tuple):  # Expected behavior
        patient_id, ok = result
        if ok and patient_id:
            return patient_id
    elif isinstance(result, str):  # If it only returns the ID as a string
        return result
    raise ValueError("No valid Patient ID entered.")

# Function to get the local path to the Chiari folder based on the hostname
def get_local_chiari_path():
    hostname = platform.node()
    if hostname == 'Guillermos-MacBook-Pro.local' or hostname == 'Guillermos-MBP':
        chiari_path = '/Users/noza/Documents/chiari'
    elif hostname == 'Lenovo':
        chiari_path = r'C:\Users\guill\Documents\chiari'

    return chiari_path

# Get Patient ID from the user
pid = get_patient_id()
if not pid:
    print("Operation canceled due to missing Patient ID.")
    exit()

# Get the local path to the Chiari folder
chiari_path = get_local_chiari_path()
segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')
pcMRI_path = os.path.join(segmentation_path, "pcMRI")

# Load the segmentation file and visualize it in 3D
raw_segmentation_file_path = os.path.join(segmentation_path, "raw_segmentation.nrrd")
raw_segmentation_node = slicer.util.loadSegmentation(raw_segmentation_file_path)
# Change the name of the loaded segmentation that will be used for the transformation
segmentation_node = slicer.util.loadSegmentation(raw_segmentation_file_path)
segmentation_node.SetName("transformed_segmentation")
segmentation_node.CreateClosedSurfaceRepresentation()
segmentation_node.GetDisplayNode().SetVisibility3D(True)

# Get all .nrrd files in the directory pcMRI and load them as Sequence
files = os.listdir(pcMRI_path)
nrrd_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]
for file_name in nrrd_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadSequence(file_path)

# Assign each view to the corresponding segment based on the relative z-location
volume_with_max_z, volume_with_min_z, volume_with_mid_z = get_volumes_with_extreme_and_mid_z()
assign_to_slices(volume_with_max_z, volume_with_min_z, volume_with_mid_z)

# Get the layout manager and adjust the slice views
layout_manager = slicer.app.layoutManager()
slice_views = ["Red", "Yellow", "Green"]
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

# Apply a linear transformation to the segmentation to align it with the sequence segmentation
# 1. Do an initial automatic linear transformation
# TODO: implement
# 2. Manually adjust the transformation if needed
response = QMessageBox.question(None, 'Manual Linear Transformation', 'Do you want to do the transformation manually?', QMessageBox.Yes | QMessageBox.No)
if response == QMessageBox.Yes:
    # Open the GUI Module Transforms on Slicer3D
    slicer.util.selectModule('Transforms')
    # Create a new transform node
    transform_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLTransformNode", "ManualTransform")
    # Create a vtkTransform object
    vtk_transform = vtk.vtkTransform()
    # TODO: set the Active Transform to the new transform node
    # Open a new QMessageBox that lets the user click "Done" when they finish the manual adjustments
    done_message_box = QMessageBox()
    done_message_box.setWindowTitle('Manual Transformation')
    done_message_box.setText('Click "Ok" when you finish the manual adjustments.')
    done_message_box.setStandardButtons(QMessageBox.Ok)
    done_message_box.exec_()
    # Apply the transform to the segmentation node
    segmentation_node = slicer.util.getNode('transformed_segmentation')
    segmentation_node.SetAndObserveTransformNodeID(transform_node.GetID())
    segmentation_display_node = segmentation_node.GetDisplayNode()

# Export the transformed segmentation as an STL file
response = QMessageBox.question(None, 'Export STL', 'Do you want to export the transformed segmentation as STL?', QMessageBox.Yes | QMessageBox.No)
if response == QMessageBox.Yes:
    export_folder = os.path.join(segmentation_path, 'stl')
    if not os.path.exists(export_folder):
        os.makedirs(export_folder)

    exporter = slicer.vtkSlicerSegmentationsModuleLogic()
    exporter.ExportSegmentsClosedSurfaceRepresentationToFiles(export_folder, segmentation_node, None, "STL")

    # Rename the exported file
    old_filename = os.path.join(export_folder, "transformed_segmentation_Segment_1.stl")
    new_filename = os.path.join(export_folder, "transformed_geometry.stl")
    if os.path.exists(old_filename):
        os.replace(old_filename, new_filename)
    else:
        raise FileNotFoundError(f"File not found: {old_filename}")

 


