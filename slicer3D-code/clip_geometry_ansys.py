# Python Script, API Version = V241
import sys
import clr
clr.AddReference("System.Windows.Forms")
from System.Windows.Forms import MessageBox, MessageBoxButtons
from System import String
from System.Collections.Generic import List
import socket

# INPUTS 
subject = sys.argv[1]
chiari_path = sys.argv[2]
ansys_version = sys.argv[3]          # e.g. "v234"


api_major = ansys_version.lower().lstrip('v')[:2]   # "23"

clr.AddReference("SpaceClaim.Api.V" + api_major)

sc = __import__("SpaceClaim.Api.V" + api_major, fromlist=["*"])
scGeometry = __import__("SpaceClaim.Api.V" + api_major + ".Geometry", fromlist=["*"])

computations_folder = os.path.join(chiari_path, 'computations')

# Open segmentation.stl
DocumentOpen.Execute(r"{}\segmentation\{}\stl\segmentation.stl".format(computations_folder, subject), FileSettings4)

# Create planes to perform clip geometry
files = List[String]()
files.Add(r"{}\ansys\{}\inputs\planes\bottom_plane.txt".format(computations_folder, subject))
files.Add(r"{}\ansys\{}\inputs\planes\top_plane.txt".format(computations_folder, subject))
    
DocumentInsert.Execute(files, FileSettings2, GetMaps("ac2373f2"))

# Create bottom Plane
selection = Curve5
result = DatumPlaneCreator.Create(selection, False, Info7)

selection = Curve2  # This assumes Curve5 refers to the imported top_plane
result = DatumPlaneCreator.Create(selection, False, Info2)
    
# Delete auxiliary curves
selection = CurveFolder1
result = Delete.Execute(selection) 

# Flatten Faceted Protrusion
for i in range(1, 11):
    result = FacetFixSharps.FindAndFix()

# Convert Bodies to Faceted Bodies.
bodies = Mesh1
result = AutoSkin.Execute(bodies)

selection = Mesh1
result = Delete.Execute(selection)

# Rename 'Patch body' to 'fluid'
selection = Body3
result = RenameObject.Execute(selection,"fluid")

MessageBox.Show(
    "1. Cut the geometry by the selected planes: Design -> Intersect -> Split Body.\n\n"
    "2. Create named selections: bottom, top, cord, dura, tonsils, (nerve_roots).\n\n"
    "3. Run save_geometry.scscript to save geometry.",
    "Manual Step",
    MessageBoxButtons.OK
)