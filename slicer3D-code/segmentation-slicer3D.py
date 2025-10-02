from qt import QInputDialog, QMessageBox
import platform
import os
import slicer
import vtk
import DICOMLib
from DICOMLib import DICOMUtils
import tempfile 
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
        if node.GetName() == "segmentation_v":
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

def save_segmentation_work(auto_seg_node, manual_seg_node, volume_node, scene_dir, scene_filename="segmentation.mrml"):
    os.makedirs(scene_dir, exist_ok=True)

    if auto_seg_node:
        if not auto_seg_node.GetStorageNode():
            auto_seg_node.CreateDefaultStorageNode()
        slicer.util.saveNode(auto_seg_node, os.path.join(scene_dir, "automatic_segmentation.seg.nrrd"))

    if manual_seg_node:
        if volume_node:
            manual_seg_node.SetReferenceImageGeometryParameterFromVolumeNode(volume_node)
        if not manual_seg_node.GetStorageNode():
            manual_seg_node.CreateDefaultStorageNode()
        slicer.util.saveNode(manual_seg_node, os.path.join(scene_dir, "manual_segmentation.seg.nrrd"))

    if volume_node:
        if not volume_node.GetStorageNode():
            volume_node.CreateDefaultStorageNode()
        slicer.util.saveNode(volume_node, os.path.join(scene_dir, "anatomy.nii.gz"))

    scene_temp_path = os.path.join(scene_dir, scene_filename)
    slicer.mrmlScene.SetURL(scene_temp_path)
    slicer.mrmlScene.Commit(scene_temp_path)

def prompt_yes_with_fallback(prompt, default):
    try:
        ans = input(prompt).strip().lower()
    except EOFError:
        ans = default  # no stdin → treat like pressing Enter
    return ans 

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

def clear_folder(folder):
    """Deletes files inside the stl folder"""
    if os.path.exists(folder):
        [os.remove(os.path.join(folder, f)) for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f))]

# def import_and_load_dicom(pcMRI_path):
#     # Open the DICOM module to initialize the database
#     slicer.util.selectModule('DICOM')

#     # Ensure the DICOM database is open
#     if not slicer.dicomDatabase.isOpen:
#         dicomDatabaseDir = slicer.app.temporaryPath + "/DICOM"
#         slicer.dicomDatabase.openDatabase(dicomDatabaseDir)

#     # Import the DICOM files using the existing database (without using TemporaryDICOMDatabase)
#     DICOMUtils.importDicom(pcMRI_path, slicer.dicomDatabase)
#     slicer.app.processEvents()

#     print(f"Successfully imported all DICOM files from: {pcMRI_path}")


# Main script execution starts here    
pid = sys.argv[1]
chiari_path = sys.argv[2]


segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')

# pcMRI_path = os.path.join(chiari_path, f'patient-data/{pid}/flow')

scene_temp_path  = os.path.join(tempfile.gettempdir(), "chiari", "segmentation", pid)
scene_final_path = os.path.join(chiari_path, f'computations/segmentation/{pid}/scene')

seg_temp_file  = os.path.join(scene_temp_path,  "segmentation.mrml")
seg_final_file = os.path.join(scene_final_path, "segmentation.mrml")

nii_filename = "auto_segmentation"

user_input = "no"  # default to "no"

if os.path.exists(seg_final_file):
    user_input = prompt_yes_with_fallback(f"\nA final segmentation was found at:\n  {seg_final_file}\n\n" 
                                          "Do you want to load it? ([yes]/no): ", default="yes")
if user_input in ("", "yes"):
    seg_scene_file = seg_final_file
else:
    # === Step 0: Check for seg_temp_file ===
    if os.path.exists(seg_temp_file):
        
        user_input = prompt_yes_with_fallback(f"\nA temporary segmentation was found at:\n  {seg_temp_file}\n\n" 
                                            "Do you want to load it? ([yes]/no): ", default="yes")

    if user_input in ("", "yes"):
        seg_scene_file = seg_temp_file

if user_input in ("", "yes"):
    # load the corresponding scene with manual segmentation in progress
    print(f"\nLoading scene from: {seg_scene_file}...\n")
    print("\n=== Manual steps in Slicer ===\n")
    slicer.util.loadScene(seg_temp_file)
    segmentation_node = slicer.util.getNode("automatic_segmentation") if slicer.util.getNode("automatic_segmentation", False) else None
    manual_segmentation_node = slicer.util.getNode("manual_segmentation") if slicer.util.getNode("manual_segmentation", False) else None
    volume_node = slicer.util.getNode("anatomy") if slicer.util.getNode("anatomy", False) else None
else: 
    # load automatic segmentations and anatomy volume
    print(f"\nLoading automatic segmentations and anatomy volume from: {segmentation_path}...\n")
    print("\n=== Manual steps in Slicer ===\n")
    segmentation_node = slicer.util.loadSegmentation(os.path.join(segmentation_path, f"{nii_filename}_canal_seg.nii.gz"))
    segmentation = segmentation_node.GetSegmentation()
    segmentation_node.SetName("automatic_segmentation")
    segmentation.GetSegment(segmentation.GetNthSegmentID(0)).SetName("canal_a")

    segmentation_node_2 = slicer.util.loadSegmentation(os.path.join(segmentation_path, f"{nii_filename}_seg.nii.gz"))
    segmentation_2 = segmentation_node_2.GetSegmentation()
    segment_id_2 = segmentation_2.GetNthSegmentID(0)  # Get the ID of the segment to move
    segmentation_2.GetSegment(segment_id_2).SetName("cord_a")

    display_segmentation_3D(segmentation_node)

    # Get the segmentation object inside the node
    volume_node = slicer.util.loadVolume(os.path.join(segmentation_path, f"{nii_filename}.nii.gz"))
    volume_node.SetName("anatomy")

    # import_and_load_dicom(pcMRI_path)

    slicer.util.selectModule('Data')

    print("1) Subtract cord from canal segmentation:")
    print("   • Module 'Data': move 'cord_a' into node 'automatic_segmentation'")
    print("   • Module 'Segment Editor':")
    print("       - Select 'canal_a'")
    print("       - Logical Operators → Operation: Subtract → 'cord_a'")
    print("       - Apply\n")

    repeat = True

    while repeat:
        user_input = prompt_yes_with_fallback("Type ok or press [enter] when done: ", default="ok")

        if user_input == "ok":
            repeat = False   # exit loop
        else:
            print("⚠️ Try again.")

    # Remove the second segmentation node from the scene
    slicer.mrmlScene.RemoveNode(segmentation_node_2)

    # Remove the cord_a segment from the first segmentation node
    segment_id = segmentation.GetSegmentIdBySegmentName("cord_a")
    segmentation.RemoveSegment(segment_id)
    # Create a new segmentation node
    manual_segmentation_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLSegmentationNode", "manual_segmentation")

    # open it in Segment Editor as the active node
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSegmentationNode(manual_segmentation_node)

    # Set the anatomy volume as the active master volume
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSourceVolumeNode(volume_node)

    canal_id = manual_segmentation_node.GetSegmentation().AddEmptySegment("csf")
    bg_id    = manual_segmentation_node.GetSegmentation().AddEmptySegment("background")
    
    # Rename segments
    manual_segmentation_node.GetSegmentation().GetSegment(canal_id).SetName("csf")
    manual_segmentation_node.GetSegmentation().GetSegment(bg_id).SetName("background")

    # Set colors (RGB in 0–1). Blue and Brown.
    manual_segmentation_node.GetSegmentation().GetSegment(canal_id).SetColor(0.4, 0.6, 1.0)   # blue
    manual_segmentation_node.GetSegmentation().GetSegment(bg_id).SetColor(0.55, 0.35, 0.10)    # brown
    
print("2) Create manual segmentation of remaining CSF space.")
print("   • Module 'Segment Editor':")

if user_input not in ("", "yes"):    
    print("       - With 'Paint tool; add seed regions to 'csf' and 'background' segments")
    print("       - to fill the segments: 'Grow from seeds' → 'Initialize'")
    print("       - If you like the result, click 'Apply'")
    print("       - Otherwise, click 'Cancel' and refine the painted seeds, then repeat.")
else:
    slicer.util.selectModule('Data')

print("       - Manually edit 'canal' and 'background' with Paint and Erase tools")

repeat = True

while repeat:
    user_input = prompt_yes_with_fallback("\nType '[save]' to save, type 'done' to finish:\n", default="save")
    
    if user_input in ("", "save"):
        print(f"saving scene to: {scene_temp_path}... \n")
        save_segmentation_work(segmentation_node, manual_segmentation_node, volume_node, scene_temp_path, "segmentation.mrml")
        print("       - Manually edit 'canal' and 'background' with Paint and Erase tools")

    elif user_input == "done":
        print(f"saving scene to: {scene_temp_path}...\n")
        save_segmentation_work(segmentation_node, manual_segmentation_node, volume_node, scene_temp_path, "segmentation.mrml")
        repeat = False   # exit loop  
    else:
        print("⚠️ Type 'save' or 'done'. Try again.")

print("3. Merge and export as stl.") 

# TODO: merge manual and automatic segmentations

user_input = prompt_yes_with_fallback("\nDo you want to export stl and replace previous version? (yes,[no]):\n", default="no")

if user_input=="yes":

    # Export the segmentation to STL
    exporter = slicer.vtkSlicerSegmentationsModuleLogic()
    exporter.ExportSegmentsClosedSurfaceRepresentationToFiles(scene_temp_path, segmentation_node, None, "STL")
    # Find the exported STL file (it should be the only STL file in the folder)
    exported_files = [f for f in os.listdir(export_folder) if f.endswith(".stl") and not f.startswith("._")]
    # If only one STL file is found, rename it
    default_filename = os.path.join(export_folder, exported_files[0])  # Get the exported STL file
    new_filename = os.path.join(export_folder, "segmentation.stl")
    os.rename(default_filename, new_filename)
    print(f"Exported STL file renamed to: {new_filename}")

    # Replace results from temporaty folder to final folder
    clear_folder(scene_final_path)


    
    clear_folder(scene_temp_path)

# Save the MRML scene



