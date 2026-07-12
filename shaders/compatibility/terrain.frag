#version 120

#if @useGPUShader4
    #extension GL_EXT_gpu_shader4: require
#endif

varying vec2 uv;

uniform sampler2D diffuseMap;

#if @normalMap
uniform sampler2D normalMap;
#endif

#if @blendMap
uniform sampler2D blendMap;
#endif

varying float euclideanDepth;
varying float linearDepth;

#define PER_PIXEL_LIGHTING (@normalMap || @specularMap || @forcePPL)

#if !PER_PIXEL_LIGHTING
centroid varying vec3 shadedLighting;
centroid varying vec3 shadedSpecular;
centroid varying vec3 passLighting;
centroid varying vec3 passSpecular;
#endif
varying vec3 passViewPos;
varying vec3 passNormal;

uniform vec2 screenRes;
uniform float far;

#include "lib/pbr_extras_config.glsl"

#include "lib/core/fragment.h.glsl" 

#include "vertexcolors.glsl"
#include "shadows_fragment.glsl"

#include "lib/material/parallax.glsl"
#include "fog.glsl"
#include "compatibility/normals.glsl"

void main()
{
    vec2 adjustedUV = (gl_TextureMatrix[0] * vec4(uv, 0.0, 1.0)).xy;

#if @parallax
#if PBR_POM
    // POM
    vec3 offset3d = parallaxOcclusionScan(normalMap, adjustedUV, transpose(normalToViewMatrix) * normalize(-passViewPos).xyz, normalToViewMatrix);
    vec2 offset = offset3d.xy - adjustedUV;
    
    vec2 origAdjustedUV = adjustedUV;
    adjustedUV += offset;

#if PBR_POM_GRAD
    vec2 dX;
    vec2 dY;
    parallaxDerivativeHelper(adjustedUV, origAdjustedUV, dX, dY);
    vec4 diffuseTex = texture2DGrad(diffuseMap, adjustedUV, dX, dY);
#else
    vec4 diffuseTex = texture2D(diffuseMap, adjustedUV);
#endif // PBR_POM_GRAD

#else  // POM
    vec2 offset = getParallaxOffset(transpose(normalToViewMatrix) * normalize(-passViewPos), texture2D(normalMap, adjustedUV).a);
    vec4 diffuseTex = texture2D(diffuseMap, adjustedUV + offset);
#endif // POM
#else
    vec4 diffuseTex = texture2D(diffuseMap, adjustedUV);
#endif // parallax
    
    gl_FragData[0] = vec4(diffuseTex.xyz, 1.0);

    vec4 diffuseColor = getDiffuseColor();
    gl_FragData[0].a *= diffuseColor.a;

#if @blendMap
    vec2 blendMapUV = (gl_TextureMatrix[1] * vec4(uv, 0.0, 1.0)).xy;
    gl_FragData[0].a *= texture2D(blendMap, blendMapUV).a;
#endif

#if @normalMap
#if @parallax && PBR_POM && PBR_POM_GRAD
    vec4 normalTex = texture2DGrad(normalMap, adjustedUV, dX, dY);
#else
    vec4 normalTex = texture2D(normalMap, adjustedUV);
#endif
    vec3 normal = normalTex.xyz * 2.0 - 1.0;
    normal = vec3(0.0, 0.0, 1.0);
#if @reconstructNormalZ
    normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
#endif
    vec3 viewNormal = normalToView(normal);
#else
    vec3 viewNormal = normalize(gl_NormalMatrix * passNormal);
#endif

#if @parallax && PBR_POM && PBR_POM_SHADOW
    vec3 shadow_offset = getParallaxShadowOffset(offset, origAdjustedUV, normalToViewMatrix);
    float shadowing = unshadowedLightRatioOffset(linearDepth, shadow_offset);
#else
    float shadowing = unshadowedLightRatio(linearDepth);
#endif
    
#if @parallax && PBR_SELF_SHADOW
    shadowing = selfShadowApprox(shadowing, normalMap, adjustedUV, normalToViewMatrix);
#endif
    
#if !PER_PIXEL_LIGHTING
    vec3 lighting, specular;
    lighting = mix(shadedLighting, passLighting, shadowing);
    specular = mix(shadedSpecular, passSpecular, shadowing);
    gl_FragData[0].xyz = gl_FragData[0].xyz * lighting + specular;
#else
#if @specularMap
    float shininess = 128.0; // TODO: make configurable
    vec4 specularColor = vec4(0.0, diffuseTex.a, 1.0, 1.0);
#else
    float shininess = gl_FrontMaterial.shininess;
    vec4 specularColor = getSpecularColor();
#endif

#if PBR_EARLY_TERRAIN_VERTCOLOR_AO_HACK
    diffuseColor.rgb = max(vec3(0.1), diffuseColor.rgb);
    float _vm = max(diffuseColor.r, max(diffuseColor.g, diffuseColor.b));
    _vm = min(_vm + 0.4, 1.0);
    diffuseColor.rgb /= _vm;
    specularColor.b *= _vm;
#endif

    gl_FragData[0].xyz = doLighting(gl_FragCoord.xy, passViewPos, viewNormal, shininess, shadowing,
        specularColor, getAmbientColor().xyz, getEmissionColor().xyz, diffuseColor.xyz, gl_FragData[0].xyz,
        false,
#if @specularMap
        true
#else
        false
#endif
        );
#endif

    gl_FragData[0] = applyFogAtDist(gl_FragData[0], euclideanDepth, linearDepth, far);

#if !@disableNormals && @writeNormals
    gl_FragData[1].xyz = viewNormal * 0.5 + 0.5;
#endif
    
    applyShadowDebugOverlay();
}
