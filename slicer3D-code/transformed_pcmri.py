from qt import QInputDialog, QMessageBox
import platform
import os
import slicer
import vtk

# Suppress VTK warnings and errors
vtk.vtkObject.GlobalWarningDisplayOff()

# Clear the MRML scene to delete all loaded data
slicer.mrmlScene.Clear(0)

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
transformation_path = os.path.join(segmentation_path, 'transformation')

# load transformed anatomy or anatomy

if os.path.exists(os.path.join(transformation_path, 'transformed_anatomy.nrrd')):
    volume_node = slicer.util.loadVolume(os.path.join(transformation_path, 'transformed_anatomy.nrrd'))
    segmentation_node = slicer.util.loadSegmentation(os.path.join(transformation_path, 'segmentation.stl'))
    print("loaded transformed anatomy ...")
else:
    volume_node = slicer.util.loadVolume(os.path.join(segmentation_path, "anatomy.nrrd"))
    segmentation_node = slicer.util.loadSegmentation(os.path.join(segmentation_path, 'raw_segmentation.seg.nrrd'))
    print("loaded raw anatomy ...")

# Load the segmentation file and visualize it in 3D
volume_node.SetName("anatomy")
segmentation_node.SetName("segmentation")
display_segmentation_3D(segmentation_node)

# Get all .nrrd files in the directory pcMRI and load them as Sequence
files = os.listdir(pcMRI_path)
nrrd_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]
for file_name in nrrd_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadSequence(file_path)

# Adjust setup slicer 3D to 3x2
slicer.app.layoutManager().setLayout(slicer.vtkMRMLLayoutNode.SlicerLayoutThreeOverThreeView)
slice_views = ["Red",  "Green", "Yellow", "Red+", "Green+", "Yellow+"]

# Sort the volumes by z-coordinate
sorted_volumes = get_volumes_sorted_by_z()

if len(sorted_volumes) == 5:
    id_slices = ['UPFM', 'FM', 'C1C2', 'C2C3', 'C3C4']
elif len(sorted_volumes) == 4:
    id_slices = ['FM', 'C1C2', 'C2C3', 'C3C4'] 


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

                    # Export the transformed segmentation as an STL file
                    response = QMessageBox.question(None, 'Export pcmri', 'Do you want to save results?', QMessageBox.No | QMessageBox.Yes, QMessageBox.Yes)
                    if response == QMessageBox.Yes:
                        if not os.path.exists(transformation_path):
                            os.makedirs(transformation_path)

                        # Save transformation matrix
                        save_transformation_matrix(transform_node, pcmri_transformation)
                        slicer.mrmlScene.RemoveNode(transform_node)

                        # Output the results
                        print("transformation_matrix.txt, segmentation.stl and transformed_anatomy.nrrd saved in stl folder")
                    break

    