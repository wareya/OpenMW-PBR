This repository is not associated with OpenMW

# Wareya's PBR shaders for OpenMW

Very basic minimally invasive PBR shaders for OpenMW 0.49 dev builds. Based on revision 613453c799. Don't install unless you know what you're doing. Configuration is in lighting_pbr.glsl. Implements basic lambert diffuse lighting and schlick-ggx specular lighting. Lighting math is done in (approximately) linear light.

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
