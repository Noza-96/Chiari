import platform
import os
import slicer
import vtk

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
    if volume_max_z is not None:
        slicer.app.layoutManager().sliceWidget("Red").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_max_z.GetID())
        print(f"Assigned volume '{volume_max_z.GetName()}' to the red slice view.")
    else:
        print("No volume node found for maximum z.")

    if volume_min_z is not None:
        slicer.app.layoutManager().sliceWidget("Yellow").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_min_z.GetID())
        print(f"Assigned volume '{volume_min_z.GetName()}' to the yellow slice view.")
    else:
        print("No volume node found for minimum z.")

    if volume_mid_z is not None:
        slicer.app.layoutManager().sliceWidget("Green").sliceLogic().GetSliceCompositeNode().SetBackgroundVolumeID(volume_mid_z.GetID())
        print(f"Assigned volume '{volume_mid_z.GetName()}' to the green slice view.")
    else:
        print("No volume node found for mid z.")

# Suppress VTK warnings and errors
# vtk.vtkObject.GlobalWarningDisplayOff()

pid = input("Patient ID:")

hostname = platform.node()
if hostname == 'Guillermos-MacBook-Pro.local':
    chiari_path = '/Users/noza/Documents/chiari'
elif hostname == 'Lenovo':
    chiari_path = r'C:\Users\guill\Documents\chiari'

segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')

pcMRI_path = os.path.join(segmentation_path, "pcMRI")

# Load the raw_segmentation.nrrd as both a segmentation and a volume
raw_segmentation_file_path = os.path.join(segmentation_path, "raw_segmentation.nrrd")

# Load as segmentation
segmentation_node = slicer.util.loadSegmentation(raw_segmentation_file_path)

# Change the name of the loaded segmentation
segmentation_node.SetName("transformed_segmentation")

# Load as volume
volume_node = slicer.util.loadVolume(raw_segmentation_file_path)

# Change the name of the loaded volume
volume_node.SetName("transformed_segmentation_v")

print("1. Segmentation loaded as volume and segemntation")

# Get all files in the directory pcMRI
files = os.listdir(pcMRI_path)

# Filter out .DS_Store files
valid_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]

# Load each valid .nrrd file as a sequence in Slicer
for file_name in valid_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadVolume(file_path)

print("2. PC-MRI files loaded as sequence")

# Assign each view to the corresponding segment based on the relative z-location
volume_with_max_z, volume_with_min_z, volume_with_mid_z = get_volumes_with_extreme_and_mid_z()
assign_to_slices(volume_with_max_z, volume_with_min_z, volume_with_mid_z)

print("3. PC-MRI planes asigned to three views (red, yellow, green) based on their z-location")

# Get the layout manager
layout_manager = slicer.app.layoutManager()

# List of slice view names
slice_views = ["Red", "Yellow", "Green"]

# Loop through each slice view
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

# segmentationNode = slicer.util.getNode("transformed_segmentation")
segmentation_node.CreateClosedSurfaceRepresentation()
segmentation_node.GetDisplayNode().SetVisibility3D(True)

print("4. Adjustment visualization")


