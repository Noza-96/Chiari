from qt import QInputDialog
import os, shutil
import slicer
import vtk
import tempfile 
import sys

vtk.vtkObject.GlobalWarningDisplayOff()

# Clear the MRML scene to delete all loaded data
slicer.mrmlScene.Clear(0)

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

def clear_folder(folder):
    """Deletes files inside the stl folder"""
    if os.path.exists(folder):
        [os.remove(os.path.join(folder, f)) for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f))]

# INPUTS 
pid = sys.argv[1]
chiari_path = sys.argv[2]


segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')

# pcMRI_path = os.path.join(chiari_path, f'patient-data/{pid}/flow')

scene_temp_path  = os.path.join(tempfile.gettempdir(), "chiari", "segmentation", pid)
scene_final_path = os.path.join(chiari_path, f'computations/segmentation/{pid}/stl')

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

    slicer.app.layoutManager().setLayout(slicer.vtkMRMLLayoutNode.SlicerLayoutSideBySideView)

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
repeat = True
while repeat:

    user_input = prompt_yes_with_fallback("Done. Type 'e' to exit: ", "NO")

    if user_input == "e":
        sys.exit()  
    else:
        print("⚠️ Try again.\n")



