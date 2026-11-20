#ifndef OPENMW_FRAGMENT_H_GLSL
#define OPENMW_FRAGMENT_H_GLSL

@link "lib/core/fragment.glsl" if !@useOVR_multiview
@link "lib/core/fragment_multiview.glsl" if @useOVR_multiview
@link "lib/core/lighting_fragment.glsl" if @lightingMethodClustered
@link "lib/core/lighting_fragment_legacy.glsl" if !@lightingMethodClustered

#include "lib/material/struct.glsl"

vec4 sampleReflectionMap(vec2 uv);
vec4 samplerLastShader(vec2 uv);

#if @skyBlending
vec3 sampleSkyColor(vec2 uv);
#endif

vec4 sampleOpaqueDepthTex(vec2 uv);
vec4 sampleOpaqueColorTex(vec2 uv);

vec3 doLighting(vec2 screenCoord, vec3 viewPos, inout vec3 viewNormal, float shininess, float shadowing,
    vec4 specularColor, vec3 ambientColor, vec3 emissionColor, vec3 diffuseColor, vec3 albedoColor,
    bool specIsSpecmap, bool specIsDiffusespec);

vec3 doSpecularLighting(vec2 screenCoord, vec3 viewPos, vec3 viewNormal);

Material getMaterial();

#endif  // OPENMW_FRAGMENT_H_GLSL
