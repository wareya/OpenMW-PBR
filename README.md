# Wareya's PBR shaders for OpenMW

Very basic minimally invasive PBR shaders for OpenMW. Don't install unless you know what you're doing. Configuration is in lighting_pbr.glsl. Implements basic lambert diffuse lighting and schlick-ggx specular lighting. Lighting math is done in (approximately) linear light.

Supports PBR specular materials. Red: metal, green: roughness, blue: ambient occlusion. If you want to use PBR materials where green is smoothness instead of roughness, change `PBR_MAT_ROUGHNESS_INVERTED 0` to `PBR_MAT_ROUGHNESS_INVERTED 1`.

## License

Licensed under the GNU GPL v3. See LICENSE and AUTHORS.md for more information.
