#version 120

#if @useUBO
    #extension GL_ARB_uniform_buffer_object : require
#endif

#if @useGPUShader4
    #extension GL_EXT_gpu_shader4: require
#endif

#define GROUNDCOVER

#if @diffuseMap
uniform sampler2D diffuseMap;
varying vec2 diffuseMapUV;
#endif

#if @normalMap
uniform sampler2D normalMap;
varying vec2 normalMapUV;
varying vec4 passTangent;
#endif

// Other shaders respect forcePPL, but legacy groundcover mods were designed to work with vertex lighting.
// They may do not look as intended with per-pixel lighting, so ignore this setting for now.
//#define PER_PIXEL_LIGHTING @normalMap
// No; we need per-pixel lighting to do PBR
#define PER_PIXEL_LIGHTING (@normalMap || @forcePPL)

varying float euclideanDepth;
varying float linearDepth;
uniform vec2 screenRes;

#if PER_PIXEL_LIGHTING
varying vec3 passViewPos;
#else
centroid varying vec3 passLighting;
centroid varying vec3 shadowDiffuseLighting;
#endif

varying vec3 passNormal;

#include "shadows_fragment.glsl"
#include "lighting.glsl"
#include "alpha.glsl"
#include "fog.glsl"

void main()
{
    vec3 worldNormal = normalize(passNormal);

#if @normalMap
    vec4 normalTex = texture2D(normalMap, normalMapUV);
#if NORMAL_RECONSTRUCT_Z
    normalTex.xyz = normalTex.xyz * 2.0 - 1.0;
    normalTex.z = sqrt(1.0 - normalTex.x*normalTex.x - normalTex.y*normalTex.y);
    normalTex.xyz = normalTex.xyz * 0.5 + 0.5;
#endif

    vec3 normalizedNormal = worldNormal;
    vec3 normalizedTangent = normalize(passTangent.xyz);
    vec3 binormal = cross(normalizedTangent, normalizedNormal) * passTangent.w;
    mat3 tbnTranspose = mat3(normalizedTangent, binormal, normalizedNormal);

    worldNormal = normalize(tbnTranspose * (normalTex.xyz * 2.0 - 1.0));
#endif
    vec3 viewNormal = normalize(gl_NormalMatrix * worldNormal);

#if @diffuseMap
    gl_FragData[0] = texture2D(diffuseMap, diffuseMapUV);
#else
    gl_FragData[0] = vec4(1.0);
#endif

    if (euclideanDepth > @groundcoverFadeStart)
        gl_FragData[0].a *= 1.0-smoothstep(@groundcoverFadeStart, @groundcoverFadeEnd, euclideanDepth);

    alphaTest();

    float shadowing = unshadowedLightRatio(linearDepth);

#if PBR_BYPASS || !PER_PIXEL_LIGHTING

    vec3 lighting;
#if !PER_PIXEL_LIGHTING
    lighting = passLighting + shadowDiffuseLighting * shadowing;
#else
    vec3 diffuseLight, ambientLight;
    doLighting(passViewPos, viewNormal, shadowing, diffuseLight, ambientLight);
    lighting = diffuseLight + ambientLight;
#endif

    clampLightingResult(lighting);

    gl_FragData[0].xyz *= lighting;

#else // PBR_BYPASS

    vec3 color = gl_FragData[0].xyz;
    float metallicity = 0.0;
    float roughness = 1.0;
    float ao = 1.0;
    float f0 = 0.04;
    fakePbrEstimate(color, metallicity, roughness, ao, f0);
    
    float a = 1.0;
    gl_FragData[0].xyz = doLightingPBR(a, gl_FragData[0].xyz, vec3(1.0), vec3(1.0), vec3(0.0), vec3(0.0), passViewPos, viewNormal, shadowing, metallicity, roughness, ao, f0);

#endif // PBR_BYPASS

    gl_FragData[0] = applyFogAtDist(gl_FragData[0], euclideanDepth, linearDepth);

#if !@disableNormals
    gl_FragData[1].xyz = worldNormal * 0.5 + 0.5;
#endif

    applyShadowDebugOverlay();
}
