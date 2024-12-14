import platform
import os
import slicer

pid = input("Patient ID:")

hostname = platform.node()
if hostname == 'Guillermos-MacBook-Pro.local':
    chiari_path = '/Users/noza/Documents/chiari'
else:
    raise NotImplementedError
    chiari_path = ''  # TODO: implement later

segmentation_path = os.path.join(chiari_path, f'computations/segmentation/{pid}')

pcMRI_path = os.path.join(segmentation_path, "pcMRI")

# Get all files in the directory
files = os.listdir(pcMRI_path)

# Filter out .DS_Store files
valid_files = [file for file in files if file != '.DS_Store' and file.lower().endswith('.nrrd')]

# Sort files if needed, depending on your sequence requirements
valid_files.sort()  # Optional, if you need the files in a specific order

# Load each valid .nrrd file as a sequence in Slicer
for file_name in valid_files:
    file_path = os.path.join(pcMRI_path, file_name)
    slicer.util.loadVolume(file_path)

# Optionally, create a volume sequence node if needed for the sequence
volume_node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLSequenceNode")
for file_name in valid_files:
    file_path = os.path.join(pcMRI_path, file_name)

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