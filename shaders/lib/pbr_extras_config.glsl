#ifndef LIB_PBR_CONFIG_EXTRAS
#define LIB_PBR_CONFIG_EXTRAS

#define PBR_POM 1
#define PBR_POM_NO_TEXTURELOD 0 // improves driver compatibility, but causes visual glitches. keep to 0 unless absolutely necessary
#define PBR_POM_DISABLE_ON_OBJECTS 0
#define PBR_POM_GRAD 1 // if you needed to set PBR_POM_NO_TEXTURELOD to 1, you probably need to set this to 0
#define PBR_POM_SHADOW 1
#define PBR_POM_SHADDOW_ARTIFACT_BODGE 4 // from 0 to 10
// ONLY IF you set PBR_POM_SHADDOW_ARTIFACT_BODGE to 0 for some reason:
//    you may want to use in settings.cfg [Shadows] to prevent some false shadowing:
//    use front face culling = true

#define PBR_SELF_SHADOW 1

// set to your shadowmap resolution
#define PBR_SHADOWMAP_RES (2048.0)
// set to a number between 1 and 16. values from 2 to 5 are normal, values above 5 are silly. 1 means no filtering.
#define PBR_SHADOW_FILTER_SIZE 2

// experiment
#define PBR_FAKE_SSS 1
#define PBR_FAKE_SSS_FORCE 0

// output just the albedo texture
#define NO_LIGHTING 0
// stuff the albedo texture into the normal map other pixel
#define NO_LIGHTING_HASH_PBR 0
// If you're going to use deferred shading, you probably want this
//    set to 1 to make some town terrains look less bizarre and plasticky.
// Otherwise, leave it set to 0.
#define PBR_EARLY_TERRAIN_VERTCOLOR_AO_HACK 0

#endif // LIB_PBR_CONFIG_EXTRAS