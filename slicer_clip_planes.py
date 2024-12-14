import platform
import os

pid = input("Patient ID:")

hostname = platform.node()
if hostname == 'Guillermos-MacBook-Pro.local':
    output_path = f'/Users/noza/My Drive/chiari-computations/segmentation/{pid}'
else:
    raise NotImplementedError
    output_path = '' # TODO: implement later

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
    point2 = tuple(origin[i] + xAxis[i] for i in range(3))
    # 3. A point along the Y-axis direction from the origin
    point3 = tuple(origin[i] + yAxis[i] for i in range(3))

    # Output the results
    print("Point 1 (Origin):", point1)
    print("Point 2:", point2)
    print("Point 3:", point3)

    # Optionally, save the plane parameters to a text file for later use
    output_filename = os.path.join(output_path, f"{plane_name}.txt")
    with open(output_filename, "w") as f:
        f.write(f"Point 1: {point1}\n")
        f.write(f"Point 2: {point2}\n")
        f.write(f"Point 3: {point3}\n")

    print(f"Plane points saved to {output_filename}")