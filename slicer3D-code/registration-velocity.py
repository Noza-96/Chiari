import os
import sys
import ants
import numpy as np

# Collapse 3D -> 2D
def collapse_to_2d(image):
    arr2d = image.numpy()[:, :, 0]
    return ants.from_numpy(arr2d, spacing=image.spacing[:2], origin=image.origin[:2], direction=image.direction[:2,:2])

def register_velocity_image(fixed_mask_path, moving_mask_path, moving_img_path, output_img_path):
    fixed_mask = ants.image_read(fixed_mask_path)
    moving_mask = ants.image_read(moving_mask_path)
    moving_img = ants.image_read(moving_img_path)

    fixed_2d = collapse_to_2d(fixed_mask)
    moving_2d = collapse_to_2d(moving_mask)
    image_2d = collapse_to_2d(moving_img)

    reg = ants.registration(fixed=fixed_2d, moving=moving_2d, type_of_transform="SyNAggro", dimensionality=2)
    result = ants.apply_transforms(fixed=fixed_2d, moving=image_2d, transformlist=reg["fwdtransforms"])

    arr3d = result.numpy()[:, :, np.newaxis]
    registered_img = ants.from_numpy(arr3d, origin=fixed_mask.origin, spacing=fixed_mask.spacing, direction=fixed_mask.direction)
    ants.image_write(registered_img, output_img_path)
    print(f"✅ Saved registered image: {output_img_path}")

# === MAIN SCRIPT ===
subject = sys.argv[1]
chiari_path = sys.argv[2]

registration_path = os.path.join(chiari_path, "computations", "pc-mri", subject, "registration")
segmentation_2D_folder = os.path.join(registration_path, "2D-segmentation")
input_velocity_folder = os.path.join(registration_path, "input-velocity")
output_velocity_folder = os.path.join(registration_path, "output-velocity")

# Get all locations
roi_files = [f for f in os.listdir(segmentation_2D_folder) if f.endswith("_roi.nrrd")]
locations = [f.split("_roi.nrrd")[0] for f in roi_files]

for loc in locations:
    print(f"\n📍 Registering location: {loc}")
    fixed_mask_path = os.path.join(segmentation_2D_folder, loc + "_segmentation.nrrd")
    moving_mask_path = os.path.join(segmentation_2D_folder, loc + "_roi.nrrd")

    # Count velocity frames
    N = sum(f.startswith(loc + "_u_") for f in os.listdir(input_velocity_folder))

    for n in range(1, N + 1):
        moving_img_path = os.path.join(input_velocity_folder, f"{loc}_u_{n}.nrrd")
        output_img_path = os.path.join(output_velocity_folder, f"{loc}_u_{n}.nrrd")
        register_velocity_image(fixed_mask_path, moving_mask_path, moving_img_path, output_img_path)