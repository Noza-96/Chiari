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
        # Skip the segmentation_v volume
        if node.GetName() == "anatomy":
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

# Function to adjust the slice views
def adjust_slice_views():
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
        # Enable human orientation markers
        slice_view.sliceView().mrmlSliceNode().SetOrientationMarkerType(slice_node.OrientationMarkerTypeHuman)
        slice_view.sliceView().mrmlSliceNode().SetOrientationMarkerSize(slice_node.OrientationMarkerSizeLarge)
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

def save_transformation_matrix(transform_node, save_path):
    if not transform_node:
        print("Error: No transform node found.")
        return

    # Get the transformation matrix
    matrix = vtk.vtkMatrix4x4()
    transform_node.GetMatrixTransformToParent(matrix)

    # Save matrix to a file
    with open(save_path, "w") as f:
        for row in range(4):
            f.write(" ".join(f"{matrix.GetElement(row, col):.2f}" for col in range(4)) + "\n")

# Save plane points to a text file
def save_plane_points(segmentation_path):
    for color, plane_name in zip(['Red', 'Yellow'], ['top_plane', 'bottom_plane']):
        # Get the red slice node (for FM view) and yellow slice node (for c3-c4 view)
        sliceNode = slicer.mrmlScene.GetNodeByID(f"vtkMRMLSliceNode{color}")

        # Get the SliceToRAS transform matrix (mapping slice coordinates to RAS coordinates)
        sliceToRAS = sliceNode.GetSliceToRAS()

        # Get the origin (position) of the slice (translation part of the transformation matrix)
        origin = sliceToRAS.GetElement(0, 3), sliceToRAS.GetElement(1, 3), sliceToRAS.GetElement(2, 3)

        # Get the basis vectors of the slice coordinate system
        xAxis = sliceToRAS.MultiplyPoint((1, 0, 0, 0))[:3]  # X direction in RAS coordinates
        yAxis = sliceToRAS.MultiplyPoint((0, 1, 0, 0))[:3]  # Y direction in RAS coordinates

        # Generate three points on the plane
        # 1. Origin (already computed)
        point1 = origin
        # 2. A point along the X-axis direction from the origin
        point2 = tuple(origin[i] + 5*xAxis[i] for i in range(3))
        # 3. A point along the Y-axis direction from the origin
        point3 = tuple(origin[i] + 5*yAxis[i] for i in range(3))

        # Optionally, save the plane parameters to a text file for later use
        export_folder = os.path.join(segmentation_path, 'planes')
        if not os.path.exists(export_folder):
            os.makedirs(export_folder)

        output_filename = os.path.join(export_folder, f"{plane_name}.txt")
        with open(output_filename, "w") as f:
            f.write("3d=True\n")
            f.write("polyline=False\n\n")
            f.write(f"{point1[2]} {point1[0]} {point1[1]}\n")
            f.write(f"{point2[2]} {point2[0]} {point2[1]}\n")
            f.write(f"{point3[2]} {point3[0]} {point3[1]}\n")
    # Output the results
    print("plane data saved to .txt files")

def clear_stl_folde(stl_folder):
    """Deletes files inside the stl folder"""
    if os.path.exists(stl_folder):
        [os.remove(os.path.join(stl_folder, f)) for f in os.listdir(stl_folder) if os.path.isfile(os.path.join(stl_folder, f))]

# Function to remove all .stl files in the export folder
def clear_stl_files(stl_folder):
    if os.path.exists(export_folder):
        for file in os.listdir(export_folder):
            if file.endswith(".stl"):
                os.remove(os.path.join(export_folder, file))
# Get Patient ID from the user
pid = get_patient_id()
if not pid:
    print("Operation canceled due to missing Patient ID.")
    exit()

# Get the local path to the Chiari folder
chiari_path = get_local_chiari_path()
segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')
pcMRI_path = os.path.join(segmentation_path, "pcMRI")


# Save the plane points to a text file -- FAILS TO GIVE CORRECT POINTS
# save_plane_points(segmentation_path)
volume_node = slicer.util.loadVolume(os.path.join(segmentation_path, "anatomy.nrrd"))

# Load the segmentation file and visualize it in 3D
segmentation_node = slicer.util.loadSegmentation(os.path.join(segmentation_path, 'raw_segmentation.seg.nrrd'))
segmentation_node.SetName("segmentation")
display_segmentation_3D(segmentation_node)

# Get all .nrrd files in the directory pcMRI and load them as Sequence
files = os.listdir(pcMRI_path)
nrrd_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]
for file_name in nrrd_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadSequence(file_path)

# Assign each view to the corresponding segment based on the relative z-location
volume_with_max_z, volume_with_min_z, volume_with_mid_z = get_volumes_with_extreme_and_mid_z()
assign_to_slices(volume_with_max_z, volume_with_min_z, volume_with_mid_z)

# Adjust the slice views
adjust_slice_views()

file_saved = False
# Apply a linear transformation to the segmentation to align it with the sequence segmentation
# 1. Load existing transformed segmentation, if it exists
transformed_geometry_path = os.path.join(segmentation_path, 'stl', 'segmentation.stl')
if os.path.exists(transformed_geometry_path):
    response = QMessageBox.question(None, 'Load Existing Transformation', 'Do you want to load the existing transformed segmentation?', QMessageBox.Yes | QMessageBox.No)
    if response == QMessageBox.Yes:
        slicer.mrmlScene.RemoveNode(segmentation_node)
        segmentation_node = slicer.util.loadSegmentation(transformed_geometry_path)
        segmentation_node.SetName("segmentation")
        display_segmentation_3D(segmentation_node)

        # # Export the transformed segmentation as an STL file
        # response = QMessageBox.question(None, 'Export STL', 'Do you want update stl file?', QMessageBox.Yes | QMessageBox.No)
        # if response == QMessageBox.Yes:
        #     export_folder = os.path.join(segmentation_path, 'stl')
        #     if not os.path.exists(export_folder):
        #         os.makedirs(export_folder)

        #     clear_stl_files(export_folder)

        #     # Ensure the segment inside the segmentation node has a unique name
        #     segmentation = segmentation_node.GetSegmentation()
        #     segment_id = segmentation.GetNthSegmentID(0)  # Get the first segment ID
        #     segmentation.GetSegment(segment_id).SetName("main_segment")  # Rename the segment to avoid duplication

        #     # Export the segmentation to STL
        #     exporter = slicer.vtkSlicerSegmentationsModuleLogic()
        #     exporter.ExportSegmentsClosedSurfaceRepresentationToFiles(export_folder, segmentation_node, None, "STL")

        #     # Find the exported STL file (it should be the only STL file in the folder)
        #     exported_files = [f for f in os.listdir(export_folder) if f.endswith(".stl") and not f.startswith("._")]

        #     # If only one STL file is found, rename it
        #     if len(exported_files) == 1:
        #         default_filename = os.path.join(export_folder, exported_files[0])  # Get the exported STL file
        #         new_filename = os.path.join(export_folder, "segmentation.stl")
        #         os.rename(default_filename, new_filename)
        #         print("segmentation.stl updated in stl folder")
        #         file_saved = True

if not file_saved:
    # 2. M  anually adjust the transformation if desired
    response = QMessageBox.question(None, 'Manual Linear Transformation', 'Do you want to adjust the transformation manually?', QMessageBox.Yes | QMessageBox.No)
    if response == QMessageBox.Yes:
        # Open the GUI Module Transforms on Slicer3D
        slicer.util.selectModule('Transforms')
        # Create a new transform node
        transform_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLTransformNode", "ManualTransform")
        # Create a vtkTransform object
        vtk_transform = vtk.vtkTransform()
        # TODO: set the Active Transform to the new transform node
        # Apply the transform to the segmentation node
        segmentation_node = slicer.util.getNode('segmentation')
        segmentation_node.SetAndObserveTransformNodeID(transform_node.GetID())
        segmentation_display_node = segmentation_node.GetDisplayNode()
        display_segmentation_3D(segmentation_node, opacity2D=0.2)

        while True:
            user_input = input('Type "ok" when you have finished the manual transformation: ')
            if user_input.lower() == 'ok':

                # Export the transformed segmentation as an STL file
                response = QMessageBox.question(None, 'Export STL', 'Do you want to save results?', QMessageBox.Yes | QMessageBox.No)
                if response == QMessageBox.Yes:
                    export_folder = os.path.join(segmentation_path, 'stl')
                    if not os.path.exists(export_folder):
                        os.makedirs(export_folder)

                    # Clear the STL folder before saving the new file
                    clear_stl_folde(export_folder)

                    # Save transformation matrix
                    transform_matrix_path = os.path.join(segmentation_path, 'stl', 'transformation_matrix.txt')
                    save_transformation_matrix(transform_node, transform_matrix_path)

                    # Apply the transformation to the volume
                    volume_node.SetAndObserveTransformNodeID(transform_node.GetID())

                    # Harden the transformation (apply it permanently)
                    slicer.vtkSlicerTransformLogic().hardenTransform(volume_node)

                    # Save the transformed volume in the STL folder
                    transformed_anatomy_path = os.path.join(segmentation_path, 'stl', 'transformed_anatomy.nrrd')
                    slicer.util.saveNode(volume_node, transformed_anatomy_path)

                    # Export the segmentation to STL
                    exporter = slicer.vtkSlicerSegmentationsModuleLogic()
                    exporter.ExportSegmentsClosedSurfaceRepresentationToFiles(export_folder, segmentation_node, None, "STL")

                    # Find the exported STL file (it should be the only STL file in the folder)
                    exported_files = [f for f in os.listdir(export_folder) if f.endswith(".stl") and not f.startswith("._")]

                    # If only one STL file is found, rename it
                    default_filename = os.path.join(export_folder, exported_files[0])  # Get the exported STL file
                    new_filename = os.path.join(export_folder, "segmentation.stl")
                    os.rename(default_filename, new_filename)

                    # Output the results
                    print("transformation_matrix.txt, segmentation.stl and transformed_anatomy.nrrd saved in stl folder")
                break

    