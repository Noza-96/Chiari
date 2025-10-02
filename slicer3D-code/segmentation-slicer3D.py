from qt import QInputDialog
import os, shutil
import slicer
import vtk
import tempfile 
import sys

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

def save_segmentation_work(auto_seg_node, volume_node, scene_dir, scene_filename="segmentation.mrml"):
    os.makedirs(scene_dir, exist_ok=True)

    if auto_seg_node:
        if not auto_seg_node.GetStorageNode():
            auto_seg_node.CreateDefaultStorageNode()
        slicer.util.saveNode(auto_seg_node, os.path.join(scene_dir, "automatic_segmentation.seg.nrrd"))

    if volume_node:
        if not volume_node.GetStorageNode():
            volume_node.CreateDefaultStorageNode()
        slicer.util.saveNode(volume_node, os.path.join(scene_dir, "anatomy.nrrd"))

    scene_temp_path = os.path.join(scene_dir, scene_filename)
    slicer.mrmlScene.SetURL(scene_temp_path)
    slicer.mrmlScene.Commit(scene_temp_path)

def prompt_yes_with_fallback(prompt, default):
    ans = default
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

if user_input not in ("", "yes"):
    # load automatic segmentations and anatomy volume
    print(f"\nLoading automatic segmentations and anatomy volume from: {segmentation_path}...\n")
    # automatic segmentation of the canal
    segmentation_node = slicer.util.loadSegmentation(os.path.join(segmentation_path, f"{nii_filename}_canal_seg.nii.gz"))
    segmentation = segmentation_node.GetSegmentation()
    segmentation_node.SetName("automatic_segmentation")
    segmentation.GetSegment(segmentation.GetNthSegmentID(0)).SetName("canal_a")
    # automatic segmentation of the cord
    segmentation_node_2 = slicer.util.loadSegmentation(os.path.join(segmentation_path, f"{nii_filename}_seg.nii.gz"))
    segmentation_2 = segmentation_node_2.GetSegmentation()
    segment_id_2 = segmentation_2.GetNthSegmentID(0)  
    segmentation_2.GetSegment(segment_id_2).SetName("cord_a")

    display_segmentation_3D(segmentation_node)
    volume_node = slicer.util.loadVolume(os.path.join(segmentation_path, f"{nii_filename}.nii.gz"))
    volume_node.SetName("anatomy")
    slicer.util.selectModule('Data')

    print("\n=== Manual steps in Slicer ===\n")

    # STEP 1: Subtract cord from canal segmentation
    print("1) Subtract cord from canal segmentation:")
    print("   • Module 'Data': move 'cord_a' into node 'automatic_segmentation'")
    print("   • Module 'Segment Editor':")
    print("       - Select 'canal_a'")
    print("       - Logical Operators → Operation: Subtract → 'cord_a'")
    print("       - Apply\n")


    repeat = True
    while repeat:
        user_input = prompt_yes_with_fallback("1.Type 's1' when done: ", "NO")

        if user_input == "s1":
            repeat = False   
        else:
            print("⚠️ Try again.")

    # Remove extra information
    slicer.mrmlScene.RemoveNode(segmentation_node_2)
    segment_id = segmentation.GetSegmentIdBySegmentName("cord_a")
    segmentation.RemoveSegment(segment_id)

    # Create a new segmentation node for manual segmentation and define segments
    manual_segmentation_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLSegmentationNode", "manual_segmentation")
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSegmentationNode(manual_segmentation_node)
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSourceVolumeNode(volume_node)
    manual_segmentation = manual_segmentation_node.GetSegmentation()
    canal_id = manual_segmentation.AddEmptySegment("csf")
    bg_id    = manual_segmentation.AddEmptySegment("background")
    manual_segmentation.GetSegment(canal_id).SetName("csf")
    manual_segmentation.GetSegment(bg_id).SetName("background")
    manual_segmentation.GetSegment(canal_id).SetColor(0.4, 0.6, 1.0)  
    manual_segmentation.GetSegment(bg_id).SetColor(0.55, 0.35, 0.10)  
      
    # STEP 2: Initialize manual segmentation
    print("2) Create manual segmentation of remaining CSF space.")
    print("   • Module 'Segment Editor':")
    print("       - With 'Paint tool; add seed regions to 'csf' and 'background' segments")
    print("       - to fill the segments: 'Grow from seeds' → 'Initialize'")
    print("       - If you like the result, click 'Apply'")
    print("       - Otherwise, click 'Cancel' and refine the painted seeds, then repeat.\n")

    repeat = True
    while repeat:
        user_input = prompt_yes_with_fallback("2.Type 's2' when done: ", "NO")

        if user_input == "s2":
            repeat = False   
        else:
            print("⚠️ Try again.")

    slicer.util.selectModule('SegmentEditor')
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSegmentationNode(segmentation_node)
    slicer.modules.segmenteditor.widgetRepresentation().self().editor.setSourceVolumeNode(volume_node)
    slicer.util.selectModule('Data')
    
    # STEP 3: Merge manual and automatic segmentations
    print("3) Merge manual and automatic segmentations.")
    print("   • Module 'Data': move 'csf' into node 'automatic_segmentation'")
    print("   • Module 'Segment Editor':")
    print("       - Select 'canal_a'")
    print("       - Logical Operators → Operation: Add → 'csf'")
    print("       - Apply\n")              

    repeat = True
    while repeat:
        user_input = prompt_yes_with_fallback("3.Type 's3' when done: ", "NO")
        if user_input == "s3":
            segmentation_node.SetName("segmentation")
            segment_id = segmentation.GetSegmentIdBySegmentName("canal_a")
            segmentation.GetSegment(segment_id).SetName("canal")
            segment_id = segmentation.GetSegmentIdBySegmentName("csf")
            segmentation.RemoveSegment(segment_id)
            slicer.mrmlScene.RemoveNode(manual_segmentation_node)  # remove manual node from scene
            print(f"saving scene to: {scene_temp_path}... \n")
            save_segmentation_work(segmentation_node, volume_node, scene_temp_path, "segmentation.mrml")
            repeat = False 
        else:
            print("⚠️ Try again.")
            
else:
    print(f"\nLoading scene from: {seg_scene_file}...\n")
    slicer.util.loadScene(seg_scene_file)
    segmentation_node = slicer.util.getNode("segmentation") if slicer.util.getNode("segmentation", False) else None
    volume_node = slicer.util.getNode("anatomy") if slicer.util.getNode("anatomy", False) else None
    slicer.util.selectModule('SegmentEditor')

# STEP 4: Final manual edits
print("4) Manual edits.") 
print("   • Module 'Segment Editor':")
print("       - Manually edit 'canal' with Paint and Erase tools")


repeat = True
while repeat:
    user_input = prompt_yes_with_fallback("\nType 'save' or [enter] to save, 's4' when done: ", default="save")
    

    if user_input in ("","save", "s3", "s4"):
        print(f"saving scene to: {scene_temp_path}... \n")
        save_segmentation_work(segmentation_node, volume_node, scene_temp_path, "segmentation.mrml")
        if user_input == "s4": 
            repeat = False
    else:
        print("⚠️ Try again.")


print("5) Export STL and exit.")
repeat = True
while repeat:
    user_input = prompt_yes_with_fallback("\nType 'export' to export STL and close Slicer: ", "no")
    if user_input == "export":
        repeat = False
    else:
        print("⚠️ Try again.")

# Export the segmentation to STL
exporter = slicer.vtkSlicerSegmentationsModuleLogic()
exporter.ExportSegmentsClosedSurfaceRepresentationToFiles(scene_temp_path, segmentation_node, None, "STL")
# Find the exported STL file (it should be the only STL file in the folder)
exported_files = [f for f in os.listdir(scene_temp_path) if f.endswith(".stl") and not f.startswith("._")]
# If only one STL file is found, rename it
default_filename = os.path.join(scene_temp_path, exported_files[0])  # Get the exported STL file
new_filename = os.path.join(scene_temp_path, "segmentation.stl")
os.rename(default_filename, new_filename)
print(f"Exported STL file renamed to: {new_filename}")
save_segmentation_work(segmentation_node, volume_node, scene_temp_path, "segmentation.mrml")

# Replace results from temporaty folder to final folder
clear_folder(scene_final_path) # clean up final folder
os.makedirs(scene_final_path, exist_ok=True) 
shutil.copytree(scene_temp_path, scene_final_path, dirs_exist_ok=True) # copy all files from temp to final folder
clear_folder(scene_temp_path) # clean up temporary folder

# Avoid "Save scene?" prompt
sys.exit()



