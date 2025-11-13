This repository is not associated with OpenMW

# Wareya's PBR shaders for OpenMW 0.50

Based on OpenMW commit 47d78e004b.

| PBR | Vanilla |
|-----|---------|
|![openmw_2025-11-12_12-12-07](https://github.com/user-attachments/assets/2f09b3d4-dbe2-4fab-b04e-11236f5b9f72)|![openmw_2025-11-12_12-12-18](https://github.com/user-attachments/assets/d3649e2d-60f4-48b7-958e-240d9b52c888)|
|![openmw_2025-11-12_12-20-43](https://github.com/user-attachments/assets/1ddc1ae5-11c5-4252-9190-b5c457355fdd)|![openmw_2025-11-12_12-20-47](https://github.com/user-attachments/assets/f9a867e2-29e8-44fc-b0cd-73571e75878f)|
|![openmw_2025-11-12_08-11-53](https://github.com/user-attachments/assets/e78d0f72-ce0a-4e25-8e9b-c1a954eb5476)|![openmw_2025-11-12_08-11-57](https://github.com/user-attachments/assets/cf1dc5d1-f6d2-4cba-babd-39485f9c49f7)|
|![openmw_2025-11-12_08-10-04](https://github.com/user-attachments/assets/cc8ed3f0-0f01-4193-b0fe-8f43b2e8bdc4)|![openmw_2025-11-12_08-10-08](https://github.com/user-attachments/assets/c3c14791-e161-4545-aec2-4c92f27d08b5)|
|![openmw_2025-11-12_12-38-11](https://github.com/user-attachments/assets/925a87d7-8bf0-4e45-9e08-4d19ede2a487)|![openmw_2025-11-12_12-38-14](https://github.com/user-attachments/assets/16aef777-b1a7-4fc9-b471-1b40161d0f2d)|
|![openmw_2025-11-12_12-46-03](https://github.com/user-attachments/assets/b5ad99cf-dfd5-46e1-99fd-bd611951acb1)|![openmw_2025-11-12_12-46-07](https://github.com/user-attachments/assets/ea2c8d8b-1cdb-4031-b61d-d3fd7e2cf7c9)|

(screenshot taken with a groundcover mod (Aesthesia) and simple post-processing shaders (like HDR))

Very basic minimally invasive PBR shaders for OpenMW. Don't install unless you know what you're doing. Make a backup of the vanilla shaders folder by COPYING it (NOT by renaming it), then copy these shaders over the base ones (DO NOT try to install this over another core shader mod! IT WILL NOT WORK!!!).

Implements basic lambert diffuse lighting and schlick-ggx specular lighting. Lighting math is done in (approximately) linear light. Configuration is in lighting_pbr.glsl.

These shaders attempt to automatically generate roughness data if there's no PBR specularity material available. To disable this, set `PBR_AUTO_ROUGHNESS_MIN` and `PBR_AUTO_ROUGHNESS_MAX` to the same value (0.75 for example).

Supports PBR specular materials. Red: metal, green: roughness, blue: ambient occlusion. If you want to use PBR materials where green is smoothness instead of roughness, change `PBR_MAT_ROUGHNESS_INVERTED 0` to `PBR_MAT_ROUGHNESS_INVERTED 1`.

Make sure you have these settings set in settings.cfg to avoid any possible issues:

```
force shaders = true
clamp lighting = false
force per pixel lighting = true
light bounds multiplier = 5
lighting method = shaders
```

## License

Licensed under the GNU GPL v3. See LICENSE and AUTHORS.md for more information. AUTHORS.md contains a list of contributors to OpenMW, only some of which have contributed to the shader code that these shaders are based on.

