# slicer_segmentation.py
import os
import slicer
import SegmentEditorEffects

# Args
import sys
subject = sys.argv[1]
chiari_path = sys.argv[2]

segmentation_path = os.path.join(chiari_path, "computations", "segmentation", subject)
stl_path = os.path.join(segmentation_path, "stl")

registration_path = os.path.join(chiari_path, "computations", "pc-mri", subject, "registration")
segmentation_2D_folder = os.path.join(registration_path, "2D-segmentation")

# Load STL -> segmentation
def display_segmentation_3D(seg):
    seg.CreateClosedSurfaceRepresentation()
    disp = seg.GetDisplayNode()
    disp.SetVisibility3D(True)
    disp.SetOpacity3D(0.6)
    disp.SetOpacity2DFill(0.4)
    disp.SetOpacity2DOutline(0.4)

def load_stl_as_segmentation(stl_file):
    model = slicer.util.loadModel(stl_file)
    seg = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLSegmentationNode', "segmentation")
    slicer.modules.segmentations.logic().ImportModelToSegmentationNode(model, seg)
    slicer.mrmlScene.RemoveNode(model)
    seg.CreateDefaultDisplayNodes()
    display_segmentation_3D(seg)
    return seg

def segmentation_2D_slices(seg_node, roi_path, output_path):
    vol_node = slicer.util.loadVolume(roi_path)
    logic = slicer.modules.volumes.logic()
    out_vol = logic.CloneVolume(slicer.mrmlScene, vol_node, vol_node.GetName() + "_segmentation")

    segment_id = seg_node.GetSegmentation().GetNthSegmentID(0)

    SegmentEditorEffects.SegmentEditorMaskVolumeEffect.maskVolumeWithSegment(
        seg_node, segment_id, "FILL_INSIDE", [1], out_vol, out_vol, [0]*6)
    SegmentEditorEffects.SegmentEditorMaskVolumeEffect.maskVolumeWithSegment(
        seg_node, segment_id, "FILL_OUTSIDE", [0], out_vol, out_vol, [0]*6)

    slicer.util.saveNode(out_vol, output_path)
    slicer.mrmlScene.RemoveNode(vol_node)
    slicer.mrmlScene.RemoveNode(out_vol)

# Run logic
seg_node = load_stl_as_segmentation(os.path.join(stl_path, "segmentation.stl"))
roi_files = [f for f in os.listdir(segmentation_2D_folder) if f.endswith("_roi.nrrd")]
locations = [f.split("_roi.nrrd")[0] for f in roi_files]

for loc in locations:
    roi_path = os.path.join(segmentation_2D_folder, loc + "_roi.nrrd")
    out_path = os.path.join(segmentation_2D_folder, loc + "_segmentation.nrrd")
    segmentation_2D_slices(seg_node, roi_path, out_path)

slicer.util.exit()