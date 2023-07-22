#version 120

#if @useUBO
    #extension GL_ARB_uniform_buffer_object : require
#endif

#if @useGPUShader4
    #extension GL_EXT_gpu_shader4: require
#endif

#define TERRAIN

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

#define PER_PIXEL_LIGHTING (@normalMap || @forcePPL)

#if !PER_PIXEL_LIGHTING
centroid varying vec3 passLighting;
centroid varying vec3 shadowDiffuseLighting;
#endif
varying vec3 passViewPos;
varying vec3 passNormal;

uniform vec2 screenRes;

#include "vertexcolors.glsl"
#include "shadows_fragment.glsl"
#include "lighting.glsl"
#include "parallax.glsl"
#include "fog.glsl"

void main()
{
    vec2 adjustedUV = (gl_TextureMatrix[0] * vec4(uv, 0.0, 1.0)).xy;

    vec3 worldNormal = normalize(passNormal);

#if @normalMap
    vec4 normalTex = texture2D(normalMap, adjustedUV);
#if NORMAL_RECONSTRUCT_Z
    normalTex.xyz = normalTex.xyz * 2.0 - 1.0;
    normalTex.z = sqrt(1.0 - normalTex.x*normalTex.x - normalTex.y*normalTex.y);
    normalTex.xyz = normalTex.xyz * 0.5 + 0.5;
#endif

    vec3 normalizedNormal = worldNormal;
    vec3 tangent = vec3(1.0, 0.0, 0.0);
    vec3 binormal = normalize(cross(tangent, normalizedNormal));
    tangent = normalize(cross(normalizedNormal, binormal)); // note, now we need to re-cross to derive tangent again because it wasn't orthonormal
    mat3 tbnTranspose = mat3(tangent, binormal, normalizedNormal);

    worldNormal = tbnTranspose * (normalTex.xyz * 2.0 - 1.0);
    vec3 viewNormal = normalize(gl_NormalMatrix * worldNormal);
    normalize(worldNormal);
#endif

#if (!@normalMap && (@parallax || @forcePPL))
    vec3 viewNormal = gl_NormalMatrix * worldNormal;
#endif

#if @parallax
    vec3 cameraPos = (gl_ModelViewMatrixInverse * vec4(0,0,0,1)).xyz;
    vec3 objectPos = (gl_ModelViewMatrixInverse * vec4(passViewPos, 1)).xyz;
    vec3 eyeDir = normalize(cameraPos - objectPos);
    adjustedUV += getParallaxOffset(eyeDir, tbnTranspose, normalTex.a, 1.f);

    // update normal using new coordinates
    normalTex = texture2D(normalMap, adjustedUV);
#if NORMAL_RECONSTRUCT_Z
    normalTex.xyz = normalTex.xyz * 2.0 - 1.0;
    normalTex.z = sqrt(1.0 - normalTex.x*normalTex.x - normalTex.y*normalTex.y);
    normalTex.xyz = normalTex.xyz * 0.5 + 0.5;
#endif

    worldNormal = tbnTranspose * (normalTex.xyz * 2.0 - 1.0);
    viewNormal = normalize(gl_NormalMatrix * worldNormal);
    normalize(worldNormal);
#endif

    vec4 diffuseTex = texture2D(diffuseMap, adjustedUV);
    gl_FragData[0] = vec4(diffuseTex.xyz, 1.0);

#if @blendMap
    vec2 blendMapUV = (gl_TextureMatrix[1] * vec4(uv, 0.0, 1.0)).xy;
    gl_FragData[0].a *= texture2D(blendMap, blendMapUV).a;
#endif

    vec4 diffuseColor = getDiffuseColor();
    gl_FragData[0].a *= diffuseColor.a;

    float shadowing = unshadowedLightRatio(linearDepth);
    
#if PBR_BYPASS

    vec3 lighting;
#if !PER_PIXEL_LIGHTING
    lighting = passLighting + shadowDiffuseLighting * shadowing;
#else
    vec3 diffuseLight, ambientLight;
    doLighting(passViewPos, normalize(viewNormal), shadowing, diffuseLight, ambientLight);
    lighting = diffuseColor.xyz * diffuseLight + getAmbientColor().xyz * ambientLight + getEmissionColor().xyz;
#endif

    clampLightingResult(lighting);

    gl_FragData[0].xyz *= lighting;

#else // PBR_BYPASS

    vec3 color = gl_FragData[0].xyz;
    float metallicity = 0.0;
    float roughness = 1.0;
    float ao = 1.0;
    float f0 = 0.04;
#if @specularMap
    vec4 specTex = vec4(0.0, diffuseTex.a, 1.0, 1.0);
    specMapToPBR(specTex, metallicity, roughness, ao, f0);
#else
    fakePbrEstimate(color, metallicity, roughness, ao, f0);
#endif
    //roughness = mix(roughness, 0.0, gl_FrontMaterial.shininess);
    
    float a = 1.0;
    gl_FragData[0].xyz = doLightingPBR(a, gl_FragData[0].xyz, diffuseColor.xyz, getAmbientColor().xyz, getEmissionColor().xyz, getSpecularColor().xyz, passViewPos, viewNormal, shadowing, metallicity, roughness, ao, f0);

#endif // PBR_BYPASS


#if PBR_BYPASS

#if @specularMap
    float shininess = 128.0; // TODO: make configurable
    vec3 matSpec = vec3(diffuseTex.a);
#else
    float shininess = gl_FrontMaterial.shininess;
    vec3 matSpec = getSpecularColor().xyz;
#endif

    if (matSpec != vec3(0.0))
    {
#if (!@normalMap && !@parallax && !@forcePPL)
        vec3 viewNormal = gl_NormalMatrix * worldNormal;
#endif
        gl_FragData[0].xyz += getSpecular(normalize(viewNormal), normalize(passViewPos), shininess, matSpec) * shadowing;
    }
#endif

    gl_FragData[0] = applyFogAtDist(gl_FragData[0], euclideanDepth, linearDepth);

#if !@disableNormals && @writeNormals
    gl_FragData[1].xyz = worldNormal.xyz * 0.5 + 0.5;
#endif

    applyShadowDebugOverlay();
}
