import ants
import trimesh
import numpy as np
from PIL import Image, ImageDraw

# def getSTLmask_from_PCMRIplane(stl_file, pcmri_file):

#     # Load STL mesh
#     mesh = trimesh.load_mesh(stl_file)

#     # Slice plane
#     plane_image = ants.image_read(pcmri_file)
#     z_slice = plane_image.origin[2]
#     plane_origin = [0, 0, z_slice]
#     plane_normal = [0, 0, 1]

#     # Intersect
#     section = mesh.section(plane_origin=plane_origin, plane_normal=plane_normal)
#     if section is None:
#         raise ValueError("No intersection found at the specified z height.")

#     # Project to 2D
#     slice_2D, tf = section.to_2D()

#     # Convert to shapely polygons
#     polygons = slice_2D.polygons_full  # list of shapely.geometry.Polygon

#     # Define image size and resolution
#     x_res = np.round(plane_image.spacing[0], 3)
#     y_res = np.round(plane_image.spacing[1], 3)
#     bounds = slice_2D.bounds.flatten()  # (minx, miny, maxx, maxy)
#     width = int(np.ceil((bounds[2] - bounds[0]) / x_res))
#     height = int(np.ceil((bounds[3] - bounds[1]) / y_res))

#     # Create blank image
#     mask_img = Image.new('L', (width, height), 0)
#     draw = ImageDraw.Draw(mask_img)

#     # Draw polygons (including holes)
#     for poly in polygons:
#         if not poly.is_valid or poly.is_empty:
#             continue
        
#         # Draw exterior (filled)
#         exterior_coords = [((x - bounds[0]) / x_res, (bounds[3] - y) / y_res) for x, y in poly.exterior.coords]
#         draw.polygon(exterior_coords, outline=1, fill=1)
        
#         # Draw interiors (holes - unfilled)
#         for interior in poly.interiors:
#             interior_coords = [((x - bounds[0]) / x_res, (bounds[3] - y) / y_res) for x, y in interior.coords]
#             draw.polygon(interior_coords, outline=0, fill=0)

#     # Convert to numpy and reshape for ANTs
#     mask_array = np.array(mask_img).astype(np.uint8)
#     mask_3d = mask_array[:, :, np.newaxis]

#     # Get 3D transform from 2D mask back to 3D space
#     origin_3d = tf.dot([bounds[0], bounds[3], 0, 1])[:3]  # (min_x, max_y) corner to 3D
#     x_axis_3d = tf.dot([0, -1, 0, 0])[:3]  # unit step in 2D x
#     y_axis_3d = tf.dot([1, 0, 0, 0])[:3]  # unit step in 2D y (flip y because image origin is top-left)

#     # Normalize and build direction matrix (3x3)
#     x_axis_3d = x_axis_3d / np.linalg.norm(x_axis_3d)
#     y_axis_3d = y_axis_3d / np.linalg.norm(y_axis_3d)
#     z_axis_3d = np.cross(x_axis_3d, y_axis_3d)
#     direction_matrix = np.column_stack([x_axis_3d, y_axis_3d, z_axis_3d])  # shape (3,3)

#     # Create aligned ANTs image
#     ants_image = ants.from_numpy(
#         mask_3d,
#         spacing=(x_res, y_res, 1),
#         origin=tuple(origin_3d),
#         direction=direction_matrix
#     )

#     # ants.image_write(ants_image, "/Users/noza/Desktop/Carolyna/s101_b/segmentation_slice_mask.nrrd")

#     return ants_image


# Read image and segmentations
stl_file = '/Users/noza/Desktop/Carolyna/s101_b/segmentation_stl.stl'
stl_2d_file = '/Users/noza/Desktop/Carolyna/s101_b/stl_segmentation_2D.nrrd'
pcmri_ROI_file = '/Users/noza/Desktop/Carolyna/s101_b/pcmri/FM_roi.nrrd'
pcmri_velocity_file = '/Users/noza/Desktop/Carolyna/s101_b/pcmri/FM_u.nrrd'

# fixed_mask = getSTLmask_from_PCMRIplane(stl_file, pcmri_ROI_file)
fixed_mask = ants.image_read(stl_2d_file)
moving_mask = ants.image_read(pcmri_ROI_file)
moving_image = ants.image_read(pcmri_velocity_file)

# Perform non-linear registration between the segmentations
reg = ants.registration(fixed=fixed_mask,
                        moving=moving_mask,
                        type_of_transform='SyNAggro',
                        dimensionality=2,
                        verbose=True)

# Apply transform to MRI image
velocity_image_registered = ants.apply_transforms(fixed=fixed_mask,
                                                  moving=moving_image,
                                                  transformlist=reg['fwdtransforms'])


print(1)


