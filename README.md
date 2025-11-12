This repository is not associated with OpenMW

# Wareya's PBR shaders for OpenMW 0.50

Based on OpenMW commit 47d78e004b.

| PBR | Vanilla |
|-----|---------|
|![openmw_2025-11-12_08-00-45](https://github.com/user-attachments/assets/14c14e8d-4e76-4c1d-825d-8b0104c81acc)|![openmw_2025-11-12_08-00-54](https://github.com/user-attachments/assets/588d72cc-28e0-4c22-a6ae-cb5c5eb94ba5)|
|![openmw_2025-11-12_08-11-53](https://github.com/user-attachments/assets/e78d0f72-ce0a-4e25-8e9b-c1a954eb5476)|![openmw_2025-11-12_08-11-57](https://github.com/user-attachments/assets/cf1dc5d1-f6d2-4cba-babd-39485f9c49f7)|
|![openmw_2025-11-12_08-10-04](https://github.com/user-attachments/assets/cc8ed3f0-0f01-4193-b0fe-8f43b2e8bdc4)|![openmw_2025-11-12_08-10-08](https://github.com/user-attachments/assets/c3c14791-e161-4545-aec2-4c92f27d08b5)|

(screenshot taken with a groundcover mod (Aesthesia) and simple post-processing shaders (like HDR))

Very basic minimally invasive PBR shaders for OpenMW 0.49 builds. Based on revision 55107e0913. Don't install unless you know what you're doing. Make a backup of the vanilla shaders folder by COPYING it (NOT by renaming it), then copy these shaders over the base ones.

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

