import ants
import trimesh
import numpy as np
from PIL import Image, ImageDraw

# Convert 3D image (with singleton z) to 2D
def collapse_to_2d(image):
    arr = image.numpy()
    arr2d = arr[:, :, 0]  # get the only slice
    return ants.from_numpy(arr2d, spacing=image.spacing[:2], origin=image.origin[:2], direction=image.direction[:2,:2])

# Read image and segmentations
stl_2d_file = '/Users/noza/Desktop/Carolyna/s101_b/stl_segmentation_2D.nrrd'
pcmri_ROI_file = '/Users/noza/Desktop/Carolyna/s101_b/pcmri/FM_roi.nrrd'
pcmri_velocity_file = '/Users/noza/Desktop/Carolyna/s101_b/pcmri/FM_u.nrrd'

# fixed_mask = getSTLmask_from_PCMRIplane(stl_file, pcmri_ROI_file)
fixed_mask = ants.image_read(stl_2d_file)
moving_mask = ants.image_read(pcmri_ROI_file)
moving_image = ants.image_read(pcmri_velocity_file)

# Convert 3D image (with singleton z) to 2D
fixed_mask_2d = collapse_to_2d(fixed_mask)
moving_mask_2d = collapse_to_2d(moving_mask)
moving_image_2d = collapse_to_2d(moving_image)

# Registration in 2D
reg = ants.registration(fixed=fixed_mask_2d,
                        moving=moving_mask_2d,
                        type_of_transform='SyNAggro',
                        dimensionality=2,
                        verbose=True)

# Apply transform to MRI image
velocity_image_registered = ants.apply_transforms(fixed=fixed_mask_2d,
                                                  moving=moving_image_2d,
                                                  transformlist=reg['fwdtransforms'])

arr = velocity_image_registered.numpy()
arr3d = arr[:, :, np.newaxis]
velocity_image_aligned = ants.from_numpy(
    arr3d,
    origin=fixed_mask.origin,
    spacing=fixed_mask.spacing,
    direction=fixed_mask.direction
)

ants.image_write(velocity_image_aligned, '/Users/noza/Desktop/Carolyna/s101_b/pcmri/FM_u_registered.nrrd')
print(1)


